import {
  Body,
  Controller,
  Get,
  Post,
  Param,
  Patch,
  Delete,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { HouseholdsService } from './households.service';
import { JwtAuthGuard } from '../auth/jwt.guard';

@UseGuards(JwtAuthGuard)
@Controller('households')
export class HouseholdsController {
  constructor(private service: HouseholdsService) { }

  /* ===== Mis casas ===== */
  @Get()
  myHouseholds(@Req() req: any) {
    return this.service.myHouseholds(req.user.id);
  }

  /* ===== Crear casa ===== */
  @Post()
  create(@Req() req: any, @Body() dto: { name: string; currency?: string }) {
    return this.service.createHousehold(
      req.user.id,
      dto.name,
      dto.currency ?? 'EUR',
    );
  }

  /* ===== Invitaciones / Join por código ===== */
  @Post(':id/invites')
  createInvite(
    @Req() req: any,
    @Param('id') id: string,
    @Body()
    dto: { expiresInHours?: number; maxUses?: number; requireApproval?: boolean },
  ) {
    return this.service.createInvite(req.user.id, id, dto);
  }

  @Post('join')
  join(@Req() req: any, @Body() dto: { code: string }) {
    return this.service.joinByCode(req.user.id, dto.code);
  }

  @Post('join-by-code')
  joinByCode(@Req() req: any, @Body() dto: { code: string }) {
    return this.service.joinByCode(req.user.id, dto.code);
  }

  /* ===== Ledger (gastos/ingresos) ===== */

  @Post(':id/entries')
  addEntry(
    @Req() req: any,
    @Param('id') id: string,
    @Body()
    dto: {
      type: 'INCOME' | 'EXPENSE';
      amount: number | string;
      category?: string;
      note?: string;
      occursAt?: string;
    },
  ) {
    return this.service.addEntry(req.user.id, id, dto);
  }

  @Get(':id/entries')
  listEntries(
    @Req() req: any,
    @Param('id') id: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('limit') limit?: string,
  ) {
    return this.service.listEntries(req.user.id, id, {
      from,
      to,
      limit: limit ? Number(limit) : undefined,
    });
  }

  @Get(':id/summary')
  summary(
    @Req() req: any,
    @Param('id') id: string,
    @Query('month') month: string,
  ) {
    return this.service.monthlySummary(req.user.id, id, month);
  }

  @Patch(':id/entries/:entryId')
  updateEntry(
    @Req() req: any,
    @Param('id') id: string,
    @Param('entryId') entryId: string,
    @Body()
    dto: {
      type?: 'INCOME' | 'EXPENSE';
      amount?: number | string;
      category?: string | null;
      note?: string | null;
      occursAt?: string;
    },
  ) {
    return this.service.updateEntry(req.user.id, id, entryId, dto);
  }

  @Delete(':id/entries/:entryId')
  deleteEntry(
    @Req() req: any,
    @Param('id') id: string,
    @Param('entryId') entryId: string,
  ) {
    return this.service.deleteEntry(req.user.id, id, entryId);
  }

  /* ===== Ahorros ===== */

  // Metas
  @Post(':id/savings-goals')
  createSavingsGoal(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: { name: string; target: number | string; deadline?: string },
  ) {
    return this.service.createSavingsGoal(req.user.id, id, dto);
  }

  @Get(':id/savings-goals')
  listSavingsGoals(@Req() req: any, @Param('id') id: string) {
    return this.service.listSavingsGoals(req.user.id, id);
  }

  @Patch(':id/savings-goals/:goalId')
  updateSavingsGoal(
    @Req() req: any,
    @Param('id') id: string,
    @Param('goalId') goalId: string,
    @Body() dto: { name?: string; target?: number | string; deadline?: string | null },
  ) {
    return this.service.updateSavingsGoal(req.user.id, id, goalId, dto);
  }

  @Delete(':id/savings-goals/:goalId')
  deleteSavingsGoal(
    @Req() req: any,
    @Param('id') id: string,
    @Param('goalId') goalId: string,
  ) {
    return this.service.deleteSavingsGoal(req.user.id, id, goalId);
  }

  // Transacciones
  @Post(':id/savings-goals/:goalId/txns')
  addSavingsTxn(
    @Req() req: any,
    @Param('id') id: string,
    @Param('goalId') goalId: string,
    @Body()
    dto: { type: 'DEPOSIT' | 'WITHDRAW'; amount: number | string; note?: string; occursAt?: string },
  ) {
    return this.service.addSavingsTxn(req.user.id, id, goalId, dto);
  }

  @Get(':id/savings-goals/:goalId/txns')
  listSavingsTxns(
    @Req() req: any,
    @Param('id') id: string,
    @Param('goalId') goalId: string,
  ) {
    return this.service.listSavingsTxns(req.user.id, id, goalId);
  }

  @Get(':id/savings-goals/:goalId/summary')
  savingsGoalSummary(
    @Req() req: any,
    @Param('id') id: string,
    @Param('goalId') goalId: string,
  ) {
    return this.service.savingsGoalSummary(req.user.id, id, goalId);
  }
}
