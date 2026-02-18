import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { ConfirmDialogService, RecurringDefDto, ToastService } from '../../../../../shared';

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
  readonly toast = inject(ToastService);
  readonly confirmDialog = inject(ConfirmDialogService);

  async onDelete(row: RecurringDefDto): Promise<void> {
    const confirmed = await this.confirmDialog.confirm({
      title: $localize`:@@recurring.delete.title:Delete recurring definition`,
      message: $localize`:@@recurring.delete.message:Are you sure you want to delete this recurring definition?`,
      cancelText: $localize`:@@common.cancel:Cancel`,
      confirmText: $localize`:@@common.delete:Delete`,
      tone: 'danger',
    });

    if (!confirmed) return;

    this.facade.deleteRecurring(row.id).subscribe({
      next: () => {
        this.toast.success(
          $localize`:@@recurring.delete.success:Recurring definition deleted successfully.`
        );
        this.facade.refreshRecurring();
      },
      error: () => {
        this.toast.error(
          $localize`:@@recurring.delete.error:Could not delete the recurring definition. Please try again.`
        );
      },
    });
  }
}