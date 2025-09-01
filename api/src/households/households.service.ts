import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { createHash, randomBytes } from 'crypto';

type EntryKind = 'INCOME' | 'EXPENSE';

function sha256(input: string) {
  return createHash('sha256').update(input).digest('hex');
}
function makeHumanCode(len = 8) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const buf = randomBytes(len);
  let out = '';
  for (let i = 0; i < len; i++) out += alphabet[buf[i] % alphabet.length];
  return out;
}

@Injectable()
export class HouseholdsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) { }

  /* ========= helpers de membresía ========= */

  private async getMembership(userId: string, householdId: string) {
    return this.prisma.householdMember.findUnique({
      where: { householdId_userId: { householdId, userId } },
    });
  }

  private async assertMember(userId: string, householdId: string) {
    const m = await this.getMembership(userId, householdId);
    if (!m) throw new ForbiddenException('No perteneces a esta casa');
    return m;
  }

  private async assertAdmin(userId: string, householdId: string) {
    const m = await this.assertMember(userId, householdId);
    if (m.role !== 'OWNER' && m.role !== 'ADMIN') {
      throw new ForbiddenException('Requiere rol ADMIN/OWNER');
    }
  }

  /* ================= Households ================= */

  async createHousehold(userId: string, name: string, currency = 'EUR') {
    if (!name?.trim()) throw new BadRequestException('Nombre requerido');
    const h = await this.prisma.household.create({
      data: { name: name.trim(), currency: currency?.trim() || 'EUR' },
    });
    await this.prisma.householdMember.create({
      data: { householdId: h.id, userId, role: 'OWNER' },
    });
    return h;
  }

  async myHouseholds(userId: string) {
    const ms = await this.prisma.householdMember.findMany({
      where: { userId },
      include: { household: true },
      orderBy: { joinedAt: 'desc' },
    });

    return ms.map((m) => ({
      id: m.household.id,
      name: m.household.name,
      currency: m.household.currency,
      role: m.role,
      joinedAt: m.joinedAt,
    }));
  }

  /* ============== Invitaciones / Join por código ============== */

  async createInvite(
    userId: string,
    householdId: string,
    {
      expiresInHours = 48,
      maxUses = 10,
      requireApproval = true,
    }: { expiresInHours?: number; maxUses?: number; requireApproval?: boolean },
  ) {
    await this.assertAdmin(userId, householdId);
    if (expiresInHours < 1 || expiresInHours > 720)
      throw new BadRequestException('expiresInHours entre 1–720');
    if (maxUses < 1 || maxUses > 999)
      throw new BadRequestException('maxUses entre 1–999');

    const code = makeHumanCode(8);
    const codeHash = sha256(code + (process.env.INVITE_PEPPER || 'pepper'));
    const expiresAt = new Date(Date.now() + expiresInHours * 3600_000);

    await this.prisma.householdInvite.create({
      data: {
        householdId,
        codeHash,
        expiresAt,
        maxUses,
        requireApproval,
        createdBy: userId,
      },
    });

    return { code, expiresAt, maxUses, requireApproval };
  }

  async joinByCode(userId: string, code: string) {
    if (!code?.trim()) throw new BadRequestException('Código requerido');

    const normalized = code.trim().toUpperCase();
    const hash = sha256(normalized + (process.env.INVITE_PEPPER || 'pepper'));

    const invite = await this.prisma.householdInvite.findFirst({
      where: {
        codeHash: hash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (!invite) throw new BadRequestException('Código inválido o expirado');

    if (invite.uses >= invite.maxUses) {
      throw new BadRequestException('Este código ya alcanzó su límite de usos');
    }

    const already = await this.prisma.householdMember.findUnique({
      where: { householdId_userId: { householdId: invite.householdId, userId } },
    });
    if (already) return { status: 'APPROVED', householdId: invite.householdId };

    if (invite.requireApproval) {
      const existsPending = await this.prisma.householdJoinRequest.findFirst({
        where: { householdId: invite.householdId, userId, status: 'PENDING' },
      });
      if (!existsPending) {
        await this.prisma.householdJoinRequest.create({
          data: { householdId: invite.householdId, userId, inviteId: invite.id },
        });
      }
      try {
        await this.notifications.notifyNewJoinRequest(invite.householdId, userId);
      } catch (e) {
      }
      return { status: 'PENDING', householdId: invite.householdId };
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.householdMember.upsert({
        where: { householdId_userId: { householdId: invite.householdId, userId } },
        create: { householdId: invite.householdId, userId, role: 'MEMBER' },
        update: {},
      });

      await tx.householdInvite.update({
        where: { id: invite.id },
        data: { uses: { increment: 1 } },
      });
    });

    return { status: 'APPROVED', householdId: invite.householdId };
  }

  /* ================= Ledger (gastos/ingresos) ================= */

  async addEntry(
    userId: string,
    householdId: string,
    dto: {
      type: EntryKind;
      amount: number | string;
      category?: string;
      note?: string;
      occursAt?: string | Date;
    },
  ) {
    await this.assertMember(userId, householdId);

    const t = (dto.type || '').toUpperCase();
    if (t !== 'INCOME' && t !== 'EXPENSE')
      throw new BadRequestException('type debe ser INCOME o EXPENSE');

    const amountNum =
      typeof dto.amount === 'string' ? Number(dto.amount) : dto.amount;
    if (!Number.isFinite(amountNum) || amountNum <= 0)
      throw new BadRequestException('amount > 0');

    const occursAt = dto.occursAt ? new Date(dto.occursAt) : new Date();

    return this.prisma.ledgerEntry.create({
      data: {
        householdId,
        userId,
        type: t as EntryKind,
        amount: amountNum,
        category: dto.category?.trim() || null,
        note: dto.note?.trim() || null,
        occursAt,
      },
    });
  }

  async listEntries(
    userId: string,
    householdId: string,
    q: { from?: string; to?: string; limit?: number },
  ) {
    await this.assertMember(userId, householdId);

    const where: any = { householdId };
    if (q.from || q.to) {
      where.occursAt = {};
      if (q.from) where.occursAt.gte = new Date(q.from);
      if (q.to) where.occursAt.lte = new Date(q.to);
    }
    const limit = Math.min(Math.max(q.limit ?? 50, 1), 200);

    return this.prisma.ledgerEntry.findMany({
      where,
      orderBy: { occursAt: 'desc' },
      take: limit,
    });
  }

  async monthlySummary(userId: string, householdId: string, month: string) {
    await this.assertMember(userId, householdId);
    if (!/^\d{4}-\d{2}$/.test(month)) {
      throw new BadRequestException('month debe ser YYYY-MM');
    }

    const [y, m] = month.split('-').map(Number);
    const from = new Date(Date.UTC(y, m - 1, 1, 0, 0, 0));
    const to = new Date(Date.UTC(y, m, 0, 23, 59, 59, 999));

    const curr = await this.prisma.ledgerEntry.groupBy({
      by: ['type'],
      where: { householdId, occursAt: { gte: from, lte: to } },
      _sum: { amount: true },
    });

    const prev = await this.prisma.ledgerEntry.groupBy({
      by: ['type'],
      where: { householdId, occursAt: { lt: from } },
      _sum: { amount: true },
    });

    const sumBy = (
      rows: { type: 'INCOME' | 'EXPENSE'; _sum: { amount: any } }[],
      t: 'INCOME' | 'EXPENSE',
    ) => Number(rows.find((r) => r.type === t)?._sum.amount ?? 0);

    const income = sumBy(curr, 'INCOME');
    const expense = sumBy(curr, 'EXPENSE');
    const net = income - expense;

    const prevIncome = sumBy(prev, 'INCOME');
    const prevExpense = sumBy(prev, 'EXPENSE');
    const openingBalance = prevIncome - prevExpense;
    const closingBalance = openingBalance + net;

    return {
      month,
      openingBalance,
      income,
      expense,
      net,
      closingBalance,
    };
  }

  async updateEntry(
    userId: string,
    householdId: string,
    entryId: string,
    dto: {
      type?: EntryKind;
      amount?: number | string;
      category?: string | null;
      note?: string | null;
      occursAt?: string | Date;
    },
  ) {
    await this.assertMember(userId, householdId);

    const entry = await this.prisma.ledgerEntry.findUnique({
      where: { id: entryId },
    });
    if (!entry || entry.householdId !== householdId)
      throw new NotFoundException('Movimiento no encontrado');

    const m = await this.getMembership(userId, householdId);
    const isAdmin = m && (m.role === 'OWNER' || m.role === 'ADMIN');
    if (entry.userId !== userId && !isAdmin) throw new ForbiddenException();

    const data: any = {};
    if (dto.type) {
      const t = dto.type.toUpperCase();
      if (t !== 'INCOME' && t !== 'EXPENSE')
        throw new BadRequestException('type inválido');
      data.type = t;
    }
    if (dto.amount !== undefined) {
      const n = typeof dto.amount === 'string' ? Number(dto.amount) : dto.amount;
      if (!Number.isFinite(n) || n <= 0)
        throw new BadRequestException('amount > 0');
      data.amount = n;
    }
    if (dto.category !== undefined) data.category = dto.category?.trim() || null;
    if (dto.note !== undefined) data.note = dto.note?.trim() || null;
    if (dto.occursAt !== undefined) {
      const d = new Date(dto.occursAt as any);
      if (isNaN(+d)) throw new BadRequestException('occursAt inválido');
      data.occursAt = d;
    }

    return this.prisma.ledgerEntry.update({ where: { id: entryId }, data });
  }

  async deleteEntry(userId: string, householdId: string, entryId: string) {
    await this.assertMember(userId, householdId);

    const entry = await this.prisma.ledgerEntry.findUnique({
      where: { id: entryId },
    });
    if (!entry || entry.householdId !== householdId)
      throw new NotFoundException('Movimiento no encontrado');

    const m = await this.getMembership(userId, householdId);
    const isAdmin = m && (m.role === 'OWNER' || m.role === 'ADMIN');
    if (entry.userId !== userId && !isAdmin) throw new ForbiddenException();

    await this.prisma.ledgerEntry.delete({ where: { id: entryId } });
    return { ok: true };
  }

  /* ===================== Ahorros ===================== */

  // Metas
  async createSavingsGoal(
    userId: string,
    householdId: string,
    dto: { name: string; target: number | string; deadline?: string | Date },
  ) {
    await this.assertAdmin(userId, householdId);
    const target =
      typeof dto.target === 'string' ? Number(dto.target) : dto.target;
    if (!dto.name?.trim()) throw new BadRequestException('name requerido');
    if (!Number.isFinite(target) || target <= 0)
      throw new BadRequestException('target > 0');

    return this.prisma.savingsGoal.create({
      data: {
        householdId,
        name: dto.name.trim(),
        target,
        deadline: dto.deadline ? new Date(dto.deadline) : null,
        createdBy: userId,
      },
    });
  }

  async listSavingsGoals(userId: string, householdId: string) {
    await this.assertMember(userId, householdId);
    const goals = await this.prisma.savingsGoal.findMany({
      where: { householdId },
      orderBy: { createdAt: 'desc' },
    });

    const sums = await this.prisma.savingsTxn.groupBy({
      by: ['goalId', 'type'],
      where: { goalId: { in: goals.map((g) => g.id) } },
      _sum: { amount: true },
    });

    const map: Record<string, { deposit: number; withdraw: number }> = {};
    for (const s of sums) {
      const g = (map[s.goalId] ||= { deposit: 0, withdraw: 0 });
      const val = Number(s._sum.amount ?? 0);
      if (s.type === 'DEPOSIT') g.deposit += val;
      else g.withdraw += val;
    }

    return goals.map((g) => {
      const agg = map[g.id] || { deposit: 0, withdraw: 0 };
      const saved = agg.deposit - agg.withdraw;
      const pct = Math.max(0, Math.min(100, (saved / Number(g.target)) * 100));
      return { ...g, saved, progress: Number.isFinite(pct) ? pct : 0 };
    });
  }

  async updateSavingsGoal(
    userId: string,
    householdId: string,
    goalId: string,
    dto: { name?: string; target?: number | string; deadline?: string | Date | null },
  ) {
    await this.assertAdmin(userId, householdId);
    const goal = await this.prisma.savingsGoal.findUnique({ where: { id: goalId } });
    if (!goal || goal.householdId !== householdId)
      throw new NotFoundException('Meta no encontrada');

    const data: any = {};
    if (dto.name !== undefined) {
      if (!dto.name.trim())
        throw new BadRequestException('name no puede ser vacío');
      data.name = dto.name.trim();
    }
    if (dto.target !== undefined) {
      const n = typeof dto.target === 'string' ? Number(dto.target) : dto.target;
      if (!Number.isFinite(n) || n <= 0)
        throw new BadRequestException('target > 0');
      data.target = n;
    }
    if (dto.deadline !== undefined) {
      data.deadline = dto.deadline === null ? null : new Date(dto.deadline as any);
    }

    return this.prisma.savingsGoal.update({ where: { id: goalId }, data });
  }

  async listJoinRequests(
    userId: string,
    householdId: string,
    status: 'PENDING' | 'APPROVED' | 'REJECTED' = 'PENDING',
  ) {
    await this.assertAdmin(userId, householdId);

    return this.prisma.householdJoinRequest.findMany({
      where: { householdId, status },
      include: { user: { select: { id: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async decideJoinRequest(
    adminUserId: string,
    householdId: string,
    reqId: string,
    decision: 'APPROVED' | 'REJECTED',
  ) {
    await this.assertAdmin(adminUserId, householdId);

    const jr = await this.prisma.householdJoinRequest.findUnique({
      where: { id: reqId },
    });

    if (!jr || jr.householdId !== householdId) {
      throw new NotFoundException('Solicitud no encontrada');
    }
    if (jr.status !== 'PENDING') {
      throw new BadRequestException('La solicitud ya fue resuelta');
    }

    if (decision === 'APPROVED') {
      await this.prisma.$transaction(async (tx) => {
        await tx.householdMember.upsert({
          where: {
            householdId_userId: { householdId, userId: jr.userId },
          },
          create: {
            householdId,
            userId: jr.userId,
            role: 'MEMBER',
          },
          update: {},
        });

        await tx.householdJoinRequest.update({
          where: { id: reqId },
          data: {
            status: 'APPROVED',
            decidedAt: new Date(),
            decidedBy: adminUserId,
          },
        });

        await tx.householdInvite.update({
          where: { id: jr.inviteId },
          data: { uses: { increment: 1 } },
        });
      });
    } else {
      await this.prisma.householdJoinRequest.update({
        where: { id: reqId },
        data: {
          status: 'REJECTED',
          decidedAt: new Date(),
          decidedBy: adminUserId,
        },
      });
    }

    try {
      await (this.notifications as any).notifyJoinRequestDecision?.(
        householdId,
        jr.userId,
        decision,
      );
    } catch (_) { }

    return { ok: true, status: decision };
  }

  async deleteSavingsGoal(userId: string, householdId: string, goalId: string) {
    await this.assertAdmin(userId, householdId);
    const goal = await this.prisma.savingsGoal.findUnique({ where: { id: goalId } });
    if (!goal || goal.householdId !== householdId)
      throw new NotFoundException('Meta no encontrada');

    // Borrado en cascada + asientos de gasto asociados a depósitos de esta meta
    await this.prisma.$transaction(async (tx) => {
      await tx.savingsTxn.deleteMany({ where: { goalId } });
      await tx.ledgerEntry.deleteMany({
        where: {
          householdId,
          category: 'Ahorros',
          // Marcados con la etiqueta en la nota:
          note: { contains: `[AHORRO:${goalId}]` },
        },
      });
      await tx.savingsGoal.delete({ where: { id: goalId } });
    });

    return { ok: true };
  }

  // Transacciones de ahorro
  async addSavingsTxn(
    userId: string,
    householdId: string,
    goalId: string,
    dto: { type: 'DEPOSIT' | 'WITHDRAW'; amount: number | string; note?: string; occursAt?: string | Date },
  ) {
    await this.assertMember(userId, householdId);
    const goal = await this.prisma.savingsGoal.findUnique({ where: { id: goalId } });
    if (!goal || goal.householdId !== householdId)
      throw new NotFoundException('Meta no encontrada');

    const t = (dto.type || '').toUpperCase();
    if (t !== 'DEPOSIT' && t !== 'WITHDRAW')
      throw new BadRequestException('type inválido');

    const amt = typeof dto.amount === 'string' ? Number(dto.amount) : dto.amount;
    if (!Number.isFinite(amt) || amt <= 0)
      throw new BadRequestException('amount > 0');

    const when = dto.occursAt ? new Date(dto.occursAt) : new Date();
    const cleanNote = dto.note?.trim() || null;

    // IMPORTANTE: si es DEPOSIT, también crear un gasto en Ledger (categoría "Ahorros") del mismo importe/fecha
    return this.prisma.$transaction(async (tx) => {
      const savedTxn = await tx.savingsTxn.create({
        data: {
          goalId,
          userId,
          type: t as any,
          amount: amt,
          note: cleanNote,
          occursAt: when,
        },
      });

      if (t === 'DEPOSIT') {
        // Etiquetamos la nota para poder limpiar si se borra la meta
        const marker = `[AHORRO:${goalId}]`;
        await tx.ledgerEntry.create({
          data: {
            householdId,
            userId,
            type: 'EXPENSE',
            amount: amt,
            category: 'Ahorros',
            note: `${marker} Depósito ahorro: "${goal.name}"${cleanNote ? ` — ${cleanNote}` : ''}`,
            occursAt: when,
          },
        });
      }

      return savedTxn;
    });
  }

  async listSavingsTxns(userId: string, householdId: string, goalId: string) {
    await this.assertMember(userId, householdId);
    const goal = await this.prisma.savingsGoal.findUnique({ where: { id: goalId } });
    if (!goal || goal.householdId !== householdId)
      throw new NotFoundException('Meta no encontrada');

    return this.prisma.savingsTxn.findMany({
      where: { goalId },
      orderBy: { occursAt: 'desc' },
      take: 200,
    });
  }

  async savingsGoalSummary(userId: string, householdId: string, goalId: string) {
    await this.assertMember(userId, householdId);
    const goal = await this.prisma.savingsGoal.findUnique({ where: { id: goalId } });
    if (!goal || goal.householdId !== householdId)
      throw new NotFoundException('Meta no encontrada');

    const grouped = await this.prisma.savingsTxn.groupBy({
      by: ['type'],
      where: { goalId },
      _sum: { amount: true },
    });

    const dep = Number(grouped.find((g) => g.type === 'DEPOSIT')?._sum.amount ?? 0);
    const wd = Number(grouped.find((g) => g.type === 'WITHDRAW')?._sum.amount ?? 0);
    const saved = dep - wd;
    const target = Number(goal.target);
    const progress = target > 0 ? Math.max(0, Math.min(100, (saved / target) * 100)) : 0;

    return {
      goal,
      saved,
      target,
      progress,
      remaining: Math.max(0, target - saved),
    };
  }
}
