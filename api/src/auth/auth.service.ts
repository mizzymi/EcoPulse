import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma.service';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService) {}

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
