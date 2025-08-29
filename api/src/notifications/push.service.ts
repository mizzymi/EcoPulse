import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as fs from 'fs';

@Injectable()
export class PushService {
  private logger = new Logger(PushService.name);
  public ready = false;

  constructor() {
    try {
      if (admin.apps.length) { this.ready = true; return; }

      const cred = this.loadCredential();
      if (!cred) {
        this.logger.warn('FCM not initialized: no credentials provided (this is OK in dev).');
        return;
      }

      admin.initializeApp({ credential: admin.credential.cert(cred as any) });
      this.ready = true;
      this.logger.log('FCM initialized');
    } catch (e: any) {
      this.logger.error(`FCM init error: ${e.message}`);
    }
  }

  private loadCredential(): object | null {
    const jsonEnv = process.env.FCM_SERVICE_ACCOUNT_JSON;
    const base64 = process.env.FCM_SERVICE_ACCOUNT_BASE64;
    const path = process.env.FCM_SERVICE_ACCOUNT_PATH;

    if (jsonEnv && jsonEnv.trim().startsWith('{')) {
      try { return JSON.parse(jsonEnv); }
      catch (e) { this.logger.error('Invalid FCM_SERVICE_ACCOUNT_JSON: ' + (e as Error).message); }
    }

    if (base64) {
      try {
        const decoded = Buffer.from(base64, 'base64').toString('utf8');
        return JSON.parse(decoded);
      } catch (e) {
        this.logger.error('Invalid FCM_SERVICE_ACCOUNT_BASE64: ' + (e as Error).message);
      }
    }

    if (path && fs.existsSync(path)) {
      try {
        const content = fs.readFileSync(path, 'utf8');
        return JSON.parse(content);
      } catch (e) {
        this.logger.error('Cannot read FCM_SERVICE_ACCOUNT_PATH: ' + (e as Error).message);
      }
    }

    return null;
  }

  async sendToTokens(tokens: string[], payload: admin.messaging.MessagingPayload) {
    if (!this.ready || !tokens?.length) return;
    await admin.messaging().sendEachForMulticast({
      tokens,
      data: payload.data,
      notification: payload.notification,
    });
  }
}
