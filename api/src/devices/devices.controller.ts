import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('devices')
@UseGuards(JwtAuthGuard)
export class DevicesController {
  constructor(private prisma: PrismaService) {}

  @Post('register')
  async register(@Req() req: any, @Body() dto: { token: string; platform: string }) {
    await this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      update: { userId: req.user.id, platform: dto.platform, revoked: false, lastSeen: new Date() },
      create: { userId: req.user.id, token: dto.token, platform: dto.platform },
    });
    return { ok: true };
  }
}
