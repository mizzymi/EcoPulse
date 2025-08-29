import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { MailService } from './mail.service';
import { PushService } from './push.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private mail: MailService,
    private push: PushService,
    private rt: RealtimeGateway,
  ) { }

  async notifyNewJoinRequest(householdId: string, requesterId: string) {
    const admins = await this.prisma.householdMember.findMany({
      where: { householdId, role: { in: ['OWNER', 'ADMIN'] } },
      include: { user: true },
    });
    const requester = await this.prisma.user.findUnique({ where: { id: requesterId } });

    const toEmails = admins.map(a => a.user.email).filter(Boolean) as string[];
    if (toEmails.length) {
      await this.mail.send(
        toEmails,
        'Nueva solicitud para unirse a tu casa',
        `<h2>Nueva solicitud pendiente</h2>
         <p><b>${requester?.email ?? 'Usuario'}</b> quiere unirse a tu casa.</p>
         <p>Entra en la app → Casa → Solicitudes para aprobar o rechazar.</p>`,
      );
    }
    const adminIds = admins.map(a => a.userId);
    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId: { in: adminIds }, revoked: false },
      select: { token: true },
    });
    await this.push.sendToTokens(tokens.map(t => t.token), {
      notification: { title: 'Solicitud de unión', body: `${requester?.email ?? 'Alguien'} quiere unirse` },
      data: { type: 'join_request_new', householdId },
    });

    this.rt.emitToManyUsers(adminIds, 'join_request_new', {
      householdId,
      requesterId,
      requesterEmail: requester?.email ?? null,
      at: new Date().toISOString(),
    });
  }

  async notifyJoinDecision(householdId: string, requesterId: string, approved: boolean) {
    const requester = await this.prisma.user.findUnique({ where: { id: requesterId } });

    if (requester?.email) {
      await this.mail.send(
        requester.email,
        approved ? '¡Solicitud aprobada!' : 'Solicitud rechazada',
        approved
          ? `<h2>¡Bienvenido!</h2><p>Tu solicitud fue <b>aprobada</b>. Ya formas parte de la casa.</p>`
          : `<h2>Solicitud rechazada</h2><p>Un administrador ha rechazado tu solicitud.</p>`,
      );
    }

    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId: requesterId, revoked: false },
      select: { token: true },
    });
    await this.push.sendToTokens(tokens.map(t => t.token), {
      notification: { title: approved ? 'Aprobado' : 'Rechazado', body: approved ? 'Ya formas parte de la casa' : 'No autorizado' },
      data: { type: 'join_request_decision', householdId, status: approved ? 'APPROVED' : 'REJECTED' },
    });

    this.rt.emitToUser(requesterId, 'join_request_decision', {
      householdId,
      status: approved ? 'APPROVED' : 'REJECTED',
      at: new Date().toISOString(),
    });
  }
}
