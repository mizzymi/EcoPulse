import { Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { NotificationsModule } from './notifications/notifications.module';
import { HouseholdsModule } from './households/households.module';
import { RealtimeModule } from './realtime/realtime.module';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [AuthModule, RealtimeModule, NotificationsModule, HouseholdsModule],
  providers: [PrismaService],
})
export class AppModule { }
