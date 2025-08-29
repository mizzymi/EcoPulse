import { Logger } from '@nestjs/common';
import { OnGatewayConnection, OnGatewayDisconnect, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: { origin: '*' },
  path: '/realtime',
})
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() io!: Server;
  private logger = new Logger(RealtimeGateway.name);

  private socketUser = new Map<string, string>();

  handleConnection(client: Socket) {
    try {
      const auth = client.handshake.headers['authorization'] as string | undefined;
      if (!auth?.startsWith('Bearer ')) return client.disconnect(true);
      const token = auth.slice(7);
      if (!token.startsWith('dev:')) return client.disconnect(true);
      const userId = token.split(':')[1];
      if (!userId) return client.disconnect(true);

      this.socketUser.set(client.id, userId);
      client.join(`user:${userId}`);
      this.logger.log(`Socket ${client.id} conectado como user:${userId}`);
    } catch (e) {
      this.logger.error(`Error de conexión: ${(e as Error).message}`);
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = this.socketUser.get(client.id);
    if (userId) this.logger.log(`Socket ${client.id} (user:${userId}) desconectado`);
    this.socketUser.delete(client.id);
  }

  emitToUser(userId: string, event: string, payload: any) {
    this.io.to(`user:${userId}`).emit(event, payload);
  }

  emitToManyUsers(userIds: string[], event: string, payload: any) {
    userIds.forEach(uid => this.emitToUser(uid, event, payload));
  }
}
