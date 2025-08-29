import { Module } from '@nestjs/common';
import { HouseholdsController } from './households.controller';
import { HouseholdsService } from './households.service';
import { PrismaService } from '../prisma.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [HouseholdsController],
  providers: [HouseholdsService, PrismaService],
})
export class HouseholdsModule {}
