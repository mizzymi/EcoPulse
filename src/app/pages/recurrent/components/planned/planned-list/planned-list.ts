import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { ConfirmDialogService, PlannedItemDto, ToastService } from '../../../../../shared';

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
  readonly toast = inject(ToastService);
  readonly confirmDialog = inject(ConfirmDialogService);

  async onDelete(row: PlannedItemDto): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: $localize`:@@planned.delete.title:Delete planned item`,
      message: $localize`:@@planned.delete.message:Are you sure you want to delete this planned item?`,
      cancelText: $localize`:@@common.cancel:Cancel`,
      confirmText: $localize`:@@common.delete:Delete`,
      tone: 'danger',
    });

    if (!confirmed) return;

    this.facade.deletePlanned(row.id).subscribe({
      next: () => {
        this.toast.success(
          $localize`:@@planned.delete.success:Planned item deleted successfully.`
        );
        this.facade.refreshPlanned();
      },
      error: () => {
        this.toast.error(
          $localize`:@@planned.delete.error:Could not delete the planned item. Please try again.`
        );
      },
    });
  }
}