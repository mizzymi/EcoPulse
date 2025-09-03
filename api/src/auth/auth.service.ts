import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma.service';
import * as bcrypt from 'bcryptjs';
import { createHmac } from 'crypto';
import { NotificationsService } from '../notifications/notifications.service';

function hmacBase64Url(data: string, key: string) {
  return createHmac('sha256', key).update(data).digest('base64url');
}

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService, private notifications: NotificationsService,) { }

  private makeResetToken(userId: string, passwordHash: string) {
    const ts = Date.now().toString();
    const secret = process.env.RESET_SECRET || 'reset-secret';
    const pepper = process.env.RESET_PEPPER || 'pepper';
    const payload = `${userId}.${ts}`;
    const sig = hmacBase64Url(`${payload}|${passwordHash}|${pepper}`, secret);
    return `${userId}.${ts}.${sig}`;
  }

  private async verifyResetToken(token: string) {
    const parts = token.split('.');
    if (parts.length !== 3) throw new BadRequestException('Token inválido');
    const [userId, tsStr, sig] = parts;
    const ts = Number(tsStr);
    if (!userId || !Number.isFinite(ts)) throw new BadRequestException('Token inválido');

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new BadRequestException('Token inválido');

    const windowMs = Number(process.env.RESET_WINDOW_MINUTES || '30') * 60_000;
    if (Date.now() - ts > windowMs) throw new BadRequestException('Token expirado');

    const secret = process.env.RESET_SECRET || 'reset-secret';
    const pepper = process.env.RESET_PEPPER || 'pepper';
    const payload = `${userId}.${tsStr}`;
    const expected = hmacBase64Url(`${payload}|${user.passwordHash}|${pepper}`, secret);
    if (expected !== sig) throw new BadRequestException('Token inválido');

    return user;
  }

  async requestPasswordReset(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) return;

    const token = this.makeResetToken(user.id, user.passwordHash);
    
    await this.notifications.sendPasswordResetCode?.(user.email, token);

  }

  async resetPassword(token: string, newPassword: string) {
    if (!newPassword || newPassword.length < 6) {
      throw new BadRequestException('password mínimo 6 caracteres');
    }
    const user = await this.verifyResetToken(token);

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    await this.notifications.notifyPasswordChanged?.(user.email);
    return { ok: true };
  }

  async register(email: string, password: string) {
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new BadRequestException('Email ya registrado');

    if (!password || password.length < 6) throw new BadRequestException('Contraseña mínima 6 caracteres');

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: { email, passwordHash },
      select: { id: true, email: true, createdAt: true },
    });

    const accessToken = await this.sign(user.id, user.email);
    return { accessToken, user };
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('Credenciales inválidas');

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Credenciales inválidas');

    const accessToken = await this.sign(user.id, user.email);
    return { accessToken, user: { id: user.id, email: user.email, createdAt: user.createdAt } };
  }

  async me(userId: string) {
    const u = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true, email: true, createdAt: true } });
    return u;
  }

  private sign(sub: string, email: string) {
    return this.jwt.signAsync({ sub, email });
  }
}
