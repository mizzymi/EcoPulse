import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { MailService } from './mail.service';
import { PushService } from './push.service';
import { PrismaService } from '../prisma.service';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [
    RealtimeModule,    
  ],
  providers: [
    NotificationsService,
    MailService,
    PushService,
    PrismaService,       
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
