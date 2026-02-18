import { Component, EventEmitter, Output, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { takeUntilDestroyed, toSignal } from '@angular/core/rxjs-interop';
import { DestroyRef } from '@angular/core';

import { NewEntryModal, NewEntryPayload } from '../new-entry-modal/new-entry-modal';
import { ApiService, NewEntryModalService, SelectedHouseholdService, TransactionRow } from '../../services';
import { BackgroundGadient } from '../background-gadient/background-gadient';
import { AsideNavBar, BottomNavBar } from '../nav';
import { ConfirmDialog } from '../confirm-dialog/confirm-dialog';
import { BreakpointObserver } from '@angular/cdk/layout';
import { map } from 'rxjs';

@Component({
  selector: 'app-container',
  standalone: true,
  imports: [CommonModule, NewEntryModal, BackgroundGadient, BottomNavBar, AsideNavBar, ConfirmDialog],
  templateUrl: './container.html',
})
export class Container {
  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );
  public readonly modal = inject(NewEntryModalService);

  private api = inject(ApiService);
  private householdSvc = inject(SelectedHouseholdService);
  private destroyRef = inject(DestroyRef);

  @Output() entryCreated = new EventEmitter<void>();
  @Output() entryUpdated = new EventEmitter<void>();

  // If you have a default currency in your app, set it here
  // or keep the @Input if you already have it.
  public defaultCurrency = 'EUR';

  onModalSave(payload: NewEntryPayload) {
    const householdId = this.householdSvc.selectedHouseholdId();
    if (!householdId) return;

    const dto = {
      type: payload.type as any,
      amount: payload.amount,
      category: payload.categoryLabel ?? undefined,
      note: payload.note?.trim() || undefined,
      occursAt: payload.dateISO ? `${payload.dateISO}T00:00:00.000Z` : undefined,
      Type: payload.paymentMethod as any,
    };

    // ✅ EDIT
    if (this.modal.mode() === 'EDIT') {
      const entryId = this.modal.editingId();
      if (!entryId) return;

      this.api
        .updateEntry(householdId, entryId, dto)
        .pipe(takeUntilDestroyed(this.destroyRef))
        .subscribe({
          next: () => {
            this.modal.hide();
            this.entryUpdated.emit();
          },
        });

      return;
    }

    // ✅ CREATE
    this.api
      .addEntry(householdId, dto)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => {
          this.modal.hide();
          this.entryCreated.emit();
        },
      });
  }
}
