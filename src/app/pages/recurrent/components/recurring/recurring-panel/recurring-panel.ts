import { Component, EventEmitter, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { RecurringDefDto } from '../../../../../shared';

@Component({
  selector: 'app-recurring-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './recurring-panel.html',
})
export class RecurringPanel {
  readonly facade = inject(RecurrentFacade);

  @Output() create = new EventEmitter<void>();
  @Output() edit = new EventEmitter<RecurringDefDto>();

  openCreate() { this.create.emit(); }
  openEdit(row: RecurringDefDto) { this.edit.emit(row); }
  
}
