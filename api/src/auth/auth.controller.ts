import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt.guard';

@Controller('auth')
export class AuthController {
  constructor(private service: AuthService) {}

  @Post('register')
  register(@Body() dto: { email: string; password: string }) {
    return this.service.register(dto.email.trim().toLowerCase(), dto.password);
  }

  @Post('login')
  login(@Body() dto: { email: string; password: string }) {
    return this.service.login(dto.email.trim().toLowerCase(), dto.password);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: any) {
    return this.service.me(req.user.id);
  }
}
