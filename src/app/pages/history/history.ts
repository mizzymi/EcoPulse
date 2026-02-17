import { Component, inject, signal } from '@angular/core';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

import { Container, HouseHoldSelector, NewEntryModalService } from '../../shared';
import { NgIf } from '@angular/common';

import { HistoryHeader } from './components/history-header/history-header';
import { HistoryFilters } from './components/history-filters/history-filters';
import { HistoryList } from './components/history-list/history-list';
import { HistoryPagination } from './components/history-pagination/history-pagination';

import { HistoryFacade } from './state/history.facade';
import { LedgerEntryType, TransactionRow } from '../../shared';
import { ConfirmDialogService } from '../../shared';

@Component({
  selector: 'app-history',
  standalone: true,
  providers: [HistoryFacade],
  imports: [
    Container,
    HouseHoldSelector,
    NgIf,
    HistoryHeader,
    HistoryFilters,
    HistoryList,
    HistoryPagination,
  ],
  templateUrl: './history.html',
})
export class History {
  private bp = inject(BreakpointObserver);
  readonly vm = inject(HistoryFacade);
  private modal = inject(NewEntryModalService);
  private confirm = inject(ConfirmDialogService);

  readonly isSmall = toSignal(this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)), {
    initialValue: false,
  });

  // ✅ edit modal state
  readonly editOpen = signal(false);
  readonly editingRow = signal<TransactionRow | null>(null);

  onAddNew() {
    this.modal.showCreate(this.vm.rowsAll());
  }

  async onDelete(row: TransactionRow) {
    const ok = await this.confirm.confirm({
      title: $localize`:@@tx.deleteConfirm.title:Delete transaction`,
      message: $localize`:@@tx.deleteConfirm.message:This action cannot be undone.`,
      cancelText: $localize`:@@common.cancel:Cancel`,
      confirmText: $localize`:@@common.delete:Delete`,
      tone: 'danger',
    });

    if (!ok) return;
    this.vm.delete(row.id);
  }

  onEdit(row: TransactionRow) {
    this.modal.showEdit(this.vm.rowsAll(), row.id, {
      type: (row.amount < 0 ? 'EXPENSE' : 'INCOME') as any,
      amount: Math.abs(row.amount),
      currency: row.currency ?? 'EUR',
      paymentMethod: (row.paymentMethod ?? 'CASH') as any,
      categoryLabel: row.category ?? null,
      dateISO: this.toISODate(new Date(row.date)),
      recurring: false,
      note: row.note ?? '',
    });
  }

  onSearch(v: string) {
    this.vm.setSearch(v);
  }

  setCategory(v: string | null) {
    this.vm.setCategory(v);
  }

  setType(v: LedgerEntryType | null) {
    this.vm.setType(v);
  }

  next() {
    this.vm.next();
  }

  prev() {
    this.vm.prev();
  }

  private toISODate(d: Date) {
    const yyyy = String(d.getFullYear());
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }
}
