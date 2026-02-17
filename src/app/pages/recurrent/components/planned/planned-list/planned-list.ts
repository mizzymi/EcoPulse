import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { PlannedItemDto } from '../../../../../shared';

@Component({
  selector: 'app-planned-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './planned-list.html',
})
export class PlannedList {
  @Input({ required: true }) rows: PlannedItemDto[] = [];
  @Input() loading = false;

  @Output() edit = new EventEmitter<PlannedItemDto>();

  readonly facade = inject(RecurrentFacade);

  onDelete(row: PlannedItemDto): void {
    // Hook your toast/confirm system here
    this.facade.deletePlanned(row.id).subscribe({
      next: () => this.facade.refreshPlanned(),
      error: () => { },
    });
  }

  onSettle(row: PlannedItemDto): void {
    this.facade.settlePlanned(row.id).subscribe({
      next: () => this.facade.refreshPlanned(),
      error: () => { },
    });
  }
}