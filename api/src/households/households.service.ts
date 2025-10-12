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

/* ===== Helpers nuevos para PLANNED/RECURRING ===== */

function parseMonthStrict(ym?: string) {
  if (!ym) return null;
  if (!/^\d{4}-\d{2}$/.test(ym)) return null;
  const [y, m] = ym.split('-').map(Number);
  return { y, m };
}

function monthRangeUtc(ym: string) {
  const mm = parseMonthStrict(ym);
  if (!mm) throw new BadRequestException('month debe ser YYYY-MM');
  const from = new Date(Date.UTC(mm.y, mm.m - 1, 1, 0, 0, 0));
  const to = new Date(Date.UTC(mm.y, mm.m, 0, 23, 59, 59, 999));
  return { from, to, ...mm };
}

function coercePositiveAmount(val: number | string | undefined) {
  const n = typeof val === 'string' ? Number(val) : val;
  if (!Number.isFinite(n) || (n as number) <= 0) {
    throw new BadRequestException('amount > 0');
  }
  return n as number;
}

function coerceType(t?: string): EntryKind {
  const U = (t || '').toUpperCase();
  if (U !== 'INCOME' && U !== 'EXPENSE') {
    throw new BadRequestException('type debe ser INCOME o EXPENSE');
  }
  return U as EntryKind;
}

function daysInMonth(y: number, m1to12: number) {
  return new Date(Date.UTC(y, m1to12, 0)).getUTCDate();
}

/** parsea BYMONTHDAY=N de una RRULE muy básica (FREQ=MONTHLY;BYMONTHDAY=N) */
function parseByMonthDay(rrule?: string): number | null {
  if (!rrule) return null;
  const m = /BYMONTHDAY\s*=\s*(-?\d+)/i.exec(rrule);
  if (!m) return null;
  const v = Number(m[1]);
  if (!Number.isFinite(v)) return null;
  return Math.trunc(v);
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
    if (!m) throw new ForbiddenException('No perteneces a esta cuenta');
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

  async deleteHousehold(userId: string, householdId: string) {
    // existe
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { id: true },
    });
    if (!household) throw new NotFoundException('Household not found');

    // es OWNER
    const membership = await this.prisma.householdMember.findFirst({
      where: { householdId, userId },
      select: { role: true },
    });
    if (!membership) throw new ForbiddenException('Not a member of this household');
    if (membership.role !== 'OWNER') {
      throw new ForbiddenException('Only the owner can delete this household');
    }

    // hard delete: ya en cascada por FK
    await this.prisma.household.delete({ where: { id: householdId } });
    return { ok: true };
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

  async updateHousehold(
    userId: string,
    householdId: string,
    dto: { name?: string; currency?: string },
  ) {
    await this.assertAdmin(userId, householdId);

    const data: any = {};
    if (dto.name !== undefined) {
      const name = dto.name.trim();
      if (!name) throw new BadRequestException('name requerido');
      if (name.length > 64) throw new BadRequestException('name demasiado largo');
      data.name = name;
    }

    if (dto.currency !== undefined) {
      const c = dto.currency.trim().toUpperCase();
      if (!/^[A-Z]{3}$/.test(c)) {
        throw new BadRequestException('currency debe ser un código ISO de 3 letras');
      }
      data.currency = c;
    }

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('Nada para actualizar');
    }

    const updated = await this.prisma.household.update({
      where: { id: householdId },
      data,
      select: { id: true, name: true, currency: true },
    });

    return updated;
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
      } catch (e) { }
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

  async listMembers(userId: string, householdId: string) {
    await this.assertMember(userId, householdId);

    const members = await this.prisma.householdMember.findMany({
      where: { householdId },
      include: {
        user: { select: { id: true, email: true } },
      },
      orderBy: { joinedAt: 'asc' },
    });

    return members.map((m) => ({
      userId: m.userId,
      role: m.role,
      joinedAt: m.joinedAt,
      user: m.user,
    }));
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

    const t = coerceType(dto.type);
    const amountNum = coercePositiveAmount(dto.amount);
    const occursAt = dto.occursAt ? new Date(dto.occursAt) : new Date();

    return this.prisma.ledgerEntry.create({
      data: {
        householdId,
        userId,
        type: t,
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
    if (dto.type) data.type = coerceType(dto.type);
    if (dto.amount !== undefined) data.amount = coercePositiveAmount(dto.amount);
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
    const target = coercePositiveAmount(dto.target);

    if (!dto.name?.trim()) throw new BadRequestException('name requerido');

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
      data.target = coercePositiveAmount(dto.target);
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
          note: { contains: `[AHORRO: ${goal.name}]` },
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

    const amt = coercePositiveAmount(dto.amount);
    const when = dto.occursAt ? new Date(dto.occursAt) : new Date();
    const cleanNote = dto.note?.trim() || null;

    // Si es DEPOSIT, también crear un gasto en Ledger (categoría "Ahorros")
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
        const marker = `[AHORRO: ${goal.name}]`;
        await tx.ledgerEntry.create({
          data: {
            householdId,
            userId,
            type: 'EXPENSE',
            amount: amt,
            category: 'Ahorros',
            note: `${marker} ${cleanNote ? ` — ${cleanNote}` : ''}`,
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

  /* =======================================================================
   *                      NUEVO: PLANNED y RECURRING
   * ======================================================================= */

  /* -------------------- PLANNED (gastos previstos) -------------------- */

  async listPlanned(
    userId: string,
    householdId: string,
    q: { month?: string },
  ) {
    await this.assertMember(userId, householdId);

    const where: any = { householdId, settledAt: null }; // solo los no asentados para forecast
    if (q.month) {
      const { from, to } = monthRangeUtc(q.month);
      where.dueDate = { gte: from, lte: to };
    }

    return this.prisma.householdPlanned.findMany({
      where,
      orderBy: [{ dueDate: 'asc' }, { createdAt: 'asc' }],
      take: 500,
    });
  }

  async createPlanned(
    userId: string,
    householdId: string,
    dto: {
      concept: string;
      amount: number | string;
      type: 'INCOME' | 'EXPENSE';
      dueDate: string; // YYYY-MM-DD
      month?: string;
      notes?: string;
      category?: string;
    },
  ) {
    await this.assertMember(userId, householdId);

    if (!dto.concept?.trim()) throw new BadRequestException('concept requerido');
    const type = coerceType(dto.type);
    const amount = coercePositiveAmount(dto.amount);
    const dueDate = new Date(dto.dueDate);
    if (isNaN(+dueDate)) throw new BadRequestException('dueDate inválida');

    return this.prisma.householdPlanned.create({
      data: {
        householdId,
        createdBy: userId,
        concept: dto.concept.trim(),
        type,
        amount,
        dueDate,
        month: dto.month?.trim() || null, // opcional, informativo
        notes: dto.notes?.trim() || null,
        category: dto.category?.trim() || null,
        settledAt: null,
      },
    });
  }

  async updatePlanned(
    userId: string,
    householdId: string,
    plannedId: string,
    dto: {
      concept?: string;
      amount?: number | string;
      type?: 'INCOME' | 'EXPENSE';
      dueDate?: string;
      month?: string | null;
      notes?: string | null;
      category?: string | null;
    },
  ) {
    await this.assertMember(userId, householdId);

    const planned = await this.prisma.householdPlanned.findUnique({ where: { id: plannedId } });
    if (!planned || planned.householdId !== householdId)
      throw new NotFoundException('Previsto no encontrado');

    // permiso: autor o admin
    const m = await this.getMembership(userId, householdId);
    const isAdmin = m && (m.role === 'OWNER' || m.role === 'ADMIN');
    if (planned.createdBy !== userId && !isAdmin) throw new ForbiddenException();

    const data: any = {};
    if (dto.concept !== undefined) {
      if (!dto.concept.trim()) throw new BadRequestException('concept vacío');
      data.concept = dto.concept.trim();
    }
    if (dto.amount !== undefined) data.amount = coercePositiveAmount(dto.amount);
    if (dto.type !== undefined) data.type = coerceType(dto.type);
    if (dto.dueDate !== undefined) {
      const d = new Date(dto.dueDate);
      if (isNaN(+d)) throw new BadRequestException('dueDate inválida');
      data.dueDate = d;
    }
    if (dto.month !== undefined) data.month = dto.month ? dto.month.trim() : null;
    if (dto.notes !== undefined) data.notes = dto.notes?.trim() || null;
    if (dto.category !== undefined) data.category = dto.category?.trim() || null;

    return this.prisma.householdPlanned.update({ where: { id: plannedId }, data });
  }

  async deletePlanned(userId: string, householdId: string, plannedId: string) {
    await this.assertMember(userId, householdId);

    const planned = await this.prisma.householdPlanned.findUnique({ where: { id: plannedId } });
    if (!planned || planned.householdId !== householdId)
      throw new NotFoundException('Previsto no encontrado');

    const m = await this.getMembership(userId, householdId);
    const isAdmin = m && (m.role === 'OWNER' || m.role === 'ADMIN');
    if (planned.createdBy !== userId && !isAdmin) throw new ForbiddenException();

    await this.prisma.householdPlanned.delete({ where: { id: plannedId } });
    return { ok: true };
  }

  // Crea entry real y marca previsto como settled
  async settlePlanned(
    userId: string,
    householdId: string,
    plannedId: string,
    month?: string, // opcional para backfill (se ignora si quieres usar dueDate original)
  ) {
    await this.assertMember(userId, householdId);

    const planned = await this.prisma.householdPlanned.findUnique({ where: { id: plannedId } });
    if (!planned || planned.householdId !== householdId)
      throw new NotFoundException('Previsto no encontrado');
    if (planned.settledAt) {
      return { ok: true, alreadySettled: true };
    }

    const occursAt = planned.dueDate; // usamos la dueDate original
    const entryType: EntryKind = planned.type as EntryKind;

    await this.prisma.$transaction(async (tx) => {
      await tx.ledgerEntry.create({
        data: {
          householdId,
          userId,
          type: entryType,
          amount: Number(planned.amount),
          category: planned.category,
          note: planned.notes ? `[PLANNED:${planned.concept}] ${planned.notes}` : `[PLANNED:${planned.concept}]`,
          occursAt,
        },
      });

      await tx.householdPlanned.update({
        where: { id: planned.id },
        data: { settledAt: new Date() },
      });
    });

    return { ok: true };
  }

  /* -------------------- RECURRING (gastos fijos) -------------------- */

  async listRecurring(
    userId: string,
    householdId: string,
    q: { month?: string },
  ) {
    await this.assertMember(userId, householdId);

    const defs = await this.prisma.householdRecurring.findMany({
      where: { householdId, active: true },
      orderBy: { createdAt: 'desc' },
      take: 500,
    });

    if (!q.month) return defs;

    const { y, m } = monthRangeUtc(q.month);
    const dim = daysInMonth(y, m);
    return defs.map((d) => {
      let dom: number | null = null;
      const bymd = parseByMonthDay(d.rrule || undefined);
      if (bymd !== null) dom = bymd;
      else if (typeof d.dayOfMonth === 'number') dom = d.dayOfMonth;

      if (!dom) dom = 1;
      let day = dom > 0 ? dom : dim + dom + 1;
      day = Math.max(1, Math.min(dim, day));

      const occursAt = new Date(Date.UTC(y, m - 1, day, 12, 0, 0));
      return {
        ...d,
        occursAt,
        amount: Number(d.amount),
      };
    });
  }

  async createRecurring(
    userId: string,
    householdId: string,
    dto: {
      concept: string;
      amount: number | string;
      type: 'INCOME' | 'EXPENSE';
      dayOfMonth?: number;
      rrule?: string;
      notes?: string;
      category?: string;
    },
  ) {
    await this.assertAdmin(userId, householdId);

    if (!dto.concept?.trim()) throw new BadRequestException('concept requerido');
    const type = coerceType(dto.type);
    const amount = coercePositiveAmount(dto.amount);

    let dayOfMonth: number | null = null;
    let rrule: string | null = null;

    if (dto.rrule && dto.rrule.trim().length) {
      rrule = dto.rrule.trim();
    } else if (dto.dayOfMonth !== undefined && dto.dayOfMonth !== null) {
      const d = Number(dto.dayOfMonth);
      if (!Number.isInteger(d)) throw new BadRequestException('dayOfMonth inválido');
      dayOfMonth = Math.max(1, Math.min(31, d));
    } else {
      dayOfMonth = 1;
    }

    return this.prisma.householdRecurring.create({
      data: {
        householdId,
        createdBy: userId,
        active: true,
        concept: dto.concept.trim(),
        type,
        amount,
        dayOfMonth,
        rrule,
        notes: dto.notes?.trim() || null,
        category: dto.category?.trim() || null,
      },
    });
  }

  async updateRecurring(
    userId: string,
    householdId: string,
    recurringId: string,
    dto: {
      concept?: string;
      amount?: number | string;
      type?: 'INCOME' | 'EXPENSE';
      dayOfMonth?: number | null;
      rrule?: string | null;
      notes?: string | null;
      category?: string | null;
    },
  ) {
    await this.assertAdmin(userId, householdId);

    const rec = await this.prisma.householdRecurring.findUnique({ where: { id: recurringId } });
    if (!rec || rec.householdId !== householdId)
      throw new NotFoundException('Gasto fijo no encontrado');

    const data: any = {};
    if (dto.concept !== undefined) {
      if (!dto.concept.trim()) throw new BadRequestException('concept vacío');
      data.concept = dto.concept.trim();
    }
    if (dto.amount !== undefined) data.amount = coercePositiveAmount(dto.amount);
    if (dto.type !== undefined) data.type = coerceType(dto.type);

    if (dto.rrule !== undefined || dto.dayOfMonth !== undefined) {
      if (dto.rrule !== undefined) {
        data.rrule = dto.rrule ? dto.rrule.trim() : null;
        data.dayOfMonth = null;
      } else {
        if (dto.dayOfMonth === null) {
          data.dayOfMonth = null; data.rrule = null;
        } else {
          const d = Number(dto.dayOfMonth);
          if (!Number.isInteger(d)) throw new BadRequestException('dayOfMonth inválido');
          data.dayOfMonth = Math.max(1, Math.min(31, d));
          data.rrule = null;
        }
      }
    }

    if (dto.notes !== undefined) data.notes = dto.notes?.trim() || null;
    if (dto.category !== undefined) data.category = dto.category?.trim() || null;

    return this.prisma.householdRecurring.update({ where: { id: recurringId }, data });
  }

  async deleteRecurring(userId: string, householdId: string, recurringId: string) {
    await this.assertAdmin(userId, householdId);

    const rec = await this.prisma.householdRecurring.findUnique({ where: { id: recurringId } });
    if (!rec || rec.householdId !== householdId)
      throw new NotFoundException('Gasto fijo no encontrado');

    await this.prisma.householdRecurring.delete({ where: { id: recurringId } });
    return { ok: true };
  }

  async postRecurringInstance(
    userId: string,
    householdId: string,
    recurringId: string,
    dto?: { month?: string; occursAt?: string | Date },
  ) {
    await this.assertMember(userId, householdId);

    const rec = await this.prisma.householdRecurring.findUnique({ where: { id: recurringId } });
    if (!rec || rec.householdId !== householdId)
      throw new NotFoundException('Gasto fijo no encontrado');
    if (!rec.active) throw new BadRequestException('La regla no está activa');

    let occursAt: Date;
    if (dto?.occursAt) {
      const d = new Date(dto.occursAt as any);
      if (isNaN(+d)) throw new BadRequestException('occursAt inválido');
      occursAt = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 12, 0, 0, 0));
    } else {
      const target = dto?.month
        ? parseMonthStrict(dto.month)
        : parseMonthStrict(`${new Date().getUTCFullYear()}-${String(new Date().getUTCMonth() + 1).padStart(2, '0')}`);
      if (!target) throw new BadRequestException('month debe ser YYYY-MM');

      const dim = daysInMonth(target.y, target.m);
      let dom: number | null = null;
      const bymd = parseByMonthDay(rec.rrule || undefined);
      if (bymd !== null) dom = bymd;
      else if (typeof rec.dayOfMonth === 'number') dom = rec.dayOfMonth;
      if (!dom) dom = 1;
      let day = dom > 0 ? dom : dim + dom + 1;
      day = Math.max(1, Math.min(dim, day));

      occursAt = new Date(Date.UTC(target.y, target.m - 1, day, 12, 0, 0, 0));
    }

    const dayStart = new Date(Date.UTC(
      occursAt.getUTCFullYear(), occursAt.getUTCMonth(), occursAt.getUTCDate(), 0, 0, 0, 0,
    ));
    const dayEnd = new Date(Date.UTC(
      occursAt.getUTCFullYear(), occursAt.getUTCMonth(), occursAt.getUTCDate(), 23, 59, 59, 999,
    ));

    // Marcadores (legacy y nuevo)
    const canonicalText = `[RECURRING: ${rec.concept}]`;

    // Idempotencia SOLO por marker legacy en NOTE (mismo día)
    const existing = await this.prisma.ledgerEntry.findFirst({
      where: {
        householdId,
        occursAt: { gte: dayStart, lte: dayEnd },
        note: { contains: canonicalText },
      },
    });
    if (existing) return { ok: true, already: true, entry: existing };

    // Crear asiento: meter ambos textos en NOTE
    const entry = await this.prisma.ledgerEntry.create({
      data: {
        householdId,
        userId,
        type: rec.type as EntryKind,
        amount: Number(rec.amount),
        category: rec.category,
        note: rec.notes
          ? `${canonicalText} ${rec.notes}`
          : `${canonicalText}`,
        occursAt,
      },
    });

    return { ok: true, entry };
  }
}
