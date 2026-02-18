import { Component, effect, EventEmitter, inject, Output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../data/recurrent.facade';
import { PlannedPanel, PlannedList } from '../planned';
import { RecurringPanel, RecurringList } from '../recurring';
import { FiltersBar } from '../shared';
import { PlannedItemDto, RecurringDefDto } from '../../../../shared';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

type TabKey = 'PLANNED' | 'RECURRING';

@Component({
  selector: 'app-recurrent-shell',
  standalone: true,
  imports: [CommonModule, FiltersBar, PlannedPanel, RecurringPanel, RecurringList, PlannedList],
  templateUrl: './recurrent-shell.html',
})
export class RecurrentShell {
  private bp = inject(BreakpointObserver);
  readonly facade = inject(RecurrentFacade);

  isSmall = toSignal(this.bp.observe('(max-width: 639px)').pipe(map((r) => r.matches)), {
    initialValue: false,
  });

  readonly tab = signal<TabKey>('RECURRING');

  constructor() {
    effect(() => {
      const hid = this.facade.selectedHouseholdId();
      this.facade.month();
      this.facade.type();
      this.facade.category();
      this.facade.accountType();

      if (!hid) return;

      this.facade.refreshPlanned();
      this.facade.refreshRecurring();
    });
  }

  setTab(key: TabKey): void {
    this.tab.set(key);
  }

  isTabActive(key: TabKey): boolean {
    return this.tab() === key;
  }

  @Output() createPlanned = new EventEmitter<void>();
  @Output() editPlanned = new EventEmitter<PlannedItemDto>();

  @Output() createRecurring = new EventEmitter<void>();
  @Output() editRecurring = new EventEmitter<RecurringDefDto>();

}
