import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { PrismaModule } from '../prisma.module';
import { MailModule } from './mail.module';
import { PushModule } from './push.module';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [PrismaModule, MailModule, PushModule, RealtimeModule],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
