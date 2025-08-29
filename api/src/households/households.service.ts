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
  ) {}

  /* ===== Members / roles ===== */

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

  /* ===== Households ===== */

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

  /* ===== Invites / Join by code ===== */

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

    const hash = sha256(code.trim() + (process.env.INVITE_PEPPER || 'pepper'));
    const invite = await this.prisma.householdInvite.findFirst({
      where: {
        codeHash: hash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (!invite) throw new BadRequestException('Código inválido o expirado');

    const already = await this.prisma.householdMember.findUnique({
      where: { householdId_userId: { householdId: invite.householdId, userId } },
    });
    if (already)
      return { status: 'APPROVED', householdId: invite.householdId };

    if (invite.requireApproval) {
      const existsPending = await this.prisma.householdJoinRequest.findFirst({
        where: {
          householdId: invite.householdId,
          userId,
          status: 'PENDING',
        },
      });
      if (!existsPending) {
        await this.prisma.householdJoinRequest.create({
          data: {
            householdId: invite.householdId,
            userId,
            inviteId: invite.id,
          },
        });
      }
      await this.notifications.notifyNewJoinRequest(invite.householdId, userId);
      return { status: 'PENDING', householdId: invite.householdId };
    }

    await this.prisma.$transaction([
      this.prisma.householdMember.create({
        data: { householdId: invite.householdId, userId, role: 'MEMBER' },
      }),
      this.prisma.householdInvite.update({
        where: { id: invite.id },
        data: { uses: { increment: 1 } },
      }),
    ]);
    return { status: 'APPROVED', householdId: invite.householdId };
  }

  /* ===== Ledger (ingresos/gastos) ===== */

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
    if (!/^\d{4}-\d{2}$/.test(month))
      throw new BadRequestException('month debe ser YYYY-MM');

    const [y, m] = month.split('-').map(Number);
    const from = new Date(Date.UTC(y, m - 1, 1, 0, 0, 0));
    const to = new Date(Date.UTC(y, m, 0, 23, 59, 59, 999));

    const rows = await this.prisma.ledgerEntry.groupBy({
      by: ['type'],
      where: { householdId, occursAt: { gte: from, lte: to } },
      _sum: { amount: true },
    });

    const sumIncome = Number(
      rows.find((r) => r.type === 'INCOME')?._sum.amount ?? 0,
    );
    const sumExpense = Number(
      rows.find((r) => r.type === 'EXPENSE')?._sum.amount ?? 0,
    );

    return { month, income: sumIncome, expense: sumExpense, net: sumIncome - sumExpense };
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
}
