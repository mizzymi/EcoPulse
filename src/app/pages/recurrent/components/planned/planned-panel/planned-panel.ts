import { Component, EventEmitter, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { PlannedItemDto } from '../../../../../shared';

@Component({
  selector: 'app-planned-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './planned-panel.html',
})
export class PlannedPanel {
  readonly facade = inject(RecurrentFacade);

  @Output() create = new EventEmitter<void>();
  @Output() edit = new EventEmitter<PlannedItemDto>();

  openCreate() { this.create.emit(); }
  openEdit(row: PlannedItemDto) { this.edit.emit(row); }
}
