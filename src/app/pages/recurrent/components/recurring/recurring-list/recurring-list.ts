import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { RecurringDefDto } from '../../../../../shared';

@Component({
  selector: 'app-recurring-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './recurring-list.html',
})
export class RecurringList {
  @Input({ required: true }) rows: RecurringDefDto[] = [];
  @Input() loading = false;

  @Output() edit = new EventEmitter<RecurringDefDto>();

  readonly facade = inject(RecurrentFacade);

  onDelete(row: RecurringDefDto): void {
    // Hook your toast/confirm system here
    this.facade.deleteRecurring(row.id).subscribe({
      next: () => this.facade.refreshRecurring(),
      error: () => { },
    });
  }

  onPost(row: RecurringDefDto): void {
    // Posts for the selected month by default
    this.facade.postRecurring(row.id, { month: this.facade.month() }).subscribe({
      next: () => { },
      error: () => { },
    });
  }
}