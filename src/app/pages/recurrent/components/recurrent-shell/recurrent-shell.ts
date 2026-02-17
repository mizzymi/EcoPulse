// src/app/pages/recurrent/components/recurrent-shell/recurrent-shell.ts
import { Component, effect, EventEmitter, inject, Output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../data/recurrent.facade';
import { PlannedPanel, PlannedList } from '../planned';
import { RecurringPanel, RecurringList } from '../recurring';
import { FiltersBar } from '../shared';
import { PlannedItemDto, RecurringDefDto } from '../../../../shared';

type TabKey = 'PLANNED' | 'RECURRING';

@Component({
  selector: 'app-recurrent-shell',
  standalone: true,
  imports: [CommonModule, FiltersBar, PlannedPanel, RecurringPanel, RecurringList, PlannedList],
  templateUrl: './recurrent-shell.html',
})
export class RecurrentShell {
  readonly facade = inject(RecurrentFacade);

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

  @Output() createPlanned = new EventEmitter<void>();
  @Output() editPlanned = new EventEmitter<PlannedItemDto>();

  @Output() createRecurring = new EventEmitter<void>();
  @Output() editRecurring = new EventEmitter<RecurringDefDto>();

}
