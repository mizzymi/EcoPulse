import { Injectable, OnModuleInit } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService implements OnModuleInit {
  private transporter!: nodemailer.Transporter;

  async onModuleInit() {
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT || 587);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;
    const secure = String(process.env.SMTP_SECURE || '').toLowerCase() === 'true';

    if (!host || !port || !user || !pass) {
      console.warn('[MAIL] SMTP no configurado. Define SMTP_HOST/PORT/USER/PASS');
      return;
    }

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: { user, pass },
    });

    try {
      await this.transporter.verify();
      console.log('[MAIL] SMTP listo:', host, `:${port}`, secure ? '(secure)' : '');
    } catch (e) {
      console.error('[MAIL] Falló verify() del SMTP:', e);
    }
  }

  async send(to: string | string[], subject: string, html: string) {
    if (!this.transporter) {
      console.warn('[MAIL] Transporter no inicializado. ¿Faltan variables SMTP?');
      return;
    }
    const toList = Array.isArray(to) ? to : [to];
    const from = process.env.SMTP_FROM || process.env.SMTP_USER;

    const info = await this.transporter.sendMail({
      from,
      to: toList.filter(Boolean),
      subject,
      html,
    });

    console.log('[MAIL] Enviado:', { messageId: info.messageId, to: toList });
    return info;
  }
}
