import { Component, computed, inject, signal } from '@angular/core';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';
import { LangSwitcher, HouseHoldSelector, Container, PlannedItemDto, RecurringDefDto } from '../../shared';
import { RecurrentShell, AddRecurrentModal } from './components';
import { RecurrentFacade } from './data/recurrent.facade';

type AddTarget = 'PLANNED' | 'RECURRING';

@Component({
  selector: 'app-recurrent',
  standalone: true,
  imports: [LangSwitcher, HouseHoldSelector, Container, RecurrentShell, AddRecurrentModal],
  templateUrl: './recurrent.html',
})
export class Recurrent {
  private bp = inject(BreakpointObserver);
  readonly facade = inject(RecurrentFacade);

  isSmall = toSignal(this.bp.observe('(max-width: 639px)').pipe(map((r) => r.matches)), {
    initialValue: false,
  });

  // ✅ Single modal state (page-level)
  readonly open = signal(false);
  readonly modalTarget = signal<AddTarget>('PLANNED');

  // one editing slot for each type
  readonly editingPlanned = signal<PlannedItemDto | null>(null);
  readonly editingRecurring = signal<RecurringDefDto | null>(null);

  openCreate(target: AddTarget) {
    this.modalTarget.set(target);
    this.editingPlanned.set(null);
    this.editingRecurring.set(null);
    this.open.set(true);
  }

  openEditPlanned(row: PlannedItemDto) {
    this.modalTarget.set('PLANNED');
    this.editingPlanned.set(row);
    this.editingRecurring.set(null);
    this.open.set(true);
  }

  openEditRecurring(row: RecurringDefDto) {
    this.modalTarget.set('RECURRING');
    this.editingRecurring.set(row);
    this.editingPlanned.set(null);
    this.open.set(true);
  }

  close() {
    this.open.set(false);
    this.editingPlanned.set(null);
    this.editingRecurring.set(null);
  }
}
