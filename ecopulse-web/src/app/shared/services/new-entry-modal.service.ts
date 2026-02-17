import { Injectable, signal } from '@angular/core';
import { TransactionRow } from './api.service';
import { NewEntryPayload } from '../components';

type ModalMode = 'CREATE' | 'EDIT';

@Injectable({ providedIn: 'root' })
export class NewEntryModalService {
    readonly open = signal(false);
    readonly rows = signal<TransactionRow[]>([]);

    // ✅ New: edit support
    readonly mode = signal<ModalMode>('CREATE');
    readonly editingId = signal<string | null>(null);
    readonly initial = signal<Partial<NewEntryPayload> | null>(null);

    showCreate(rows: TransactionRow[] = []) {
        this.rows.set(rows);
        this.mode.set('CREATE');
        this.editingId.set(null);
        this.initial.set(null);
        this.open.set(true);
    }

    showEdit(rows: TransactionRow[], entryId: string, initial: Partial<NewEntryPayload>) {
        this.rows.set(rows);
        this.mode.set('EDIT');
        this.editingId.set(entryId);
        this.initial.set(initial ?? null);
        this.open.set(true);
    }

    hide() {
        this.open.set(false);
    }
}
