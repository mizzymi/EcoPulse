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
  constructor(private service: HouseholdsService) {}

  // Mis casas
  @Get()
  myHouseholds(@Req() req: any) {
    return this.service.myHouseholds(req.user.id);
  }

  // Crear casa
  @Post()
  create(@Req() req: any, @Body() dto: { name: string; currency?: string }) {
    return this.service.createHousehold(
      req.user.id,
      dto.name,
      dto.currency ?? 'EUR',
    );
  }

  // Generar invitación
  @Post(':id/invites')
  createInvite(
    @Req() req: any,
    @Param('id') id: string,
    @Body()
    dto: { expiresInHours?: number; maxUses?: number; requireApproval?: boolean },
  ) {
    return this.service.createInvite(req.user.id, id, dto);
  }

  // Unirse por código (ruta clásica)
  @Post('join')
  join(@Req() req: any, @Body() dto: { code: string }) {
    return this.service.joinByCode(req.user.id, dto.code);
  }

  // Alias opcional
  @Post('join-by-code')
  joinByCode(@Req() req: any, @Body() dto: { code: string }) {
    return this.service.joinByCode(req.user.id, dto.code);
  }

  /* ===== Movimientos ===== */

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
}
