import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

import { SavingsFacade } from '../../data/savings.facade';
import { GoalCard } from '../goal-card/goal-card';
import { SavingsGoalDto, ConfirmDialogService, ToastService } from '../../../../shared';

@Component({
  selector: 'app-goals-grid',
  standalone: true,
  imports: [CommonModule, GoalCard],
  templateUrl: './goals-grid.html',
})
export class GoalsGrid {
  readonly facade = inject(SavingsFacade);
  private readonly router = inject(Router);
  private readonly confirm = inject(ConfirmDialogService);
  private readonly toast = inject(ToastService);

  trackById = (_: number, g: SavingsGoalDto) => g.id;

  onOpen(goalId: string) {
    this.router.navigate(['/saving', goalId]);
  }

  async onDelete(goalId: string) {
    const ok = await this.confirm.confirm({
      title: $localize`:@@savings.goal.deleteConfirm.title:Delete goal`,
      message: $localize`:@@savings.goal.deleteConfirm.message:This action cannot be undone.`,
      cancelText: $localize`:@@common.cancel:Cancel`,
      confirmText: $localize`:@@common.delete:Delete`,
      tone: 'danger',
    });

    if (!ok) return;

    this.facade.deleteGoal(goalId).subscribe({
      next: () => this.toast.success($localize`:@@savings.goal.deleted:Goal deleted`),
      error: (e: any) => {
        const msg =
          typeof e?.message === 'string' && e.message.trim()
            ? e.message
            : $localize`:@@savings.err.deleteFailed:Failed to delete goal`;
        this.toast.error(msg);
      },
    });
  }
}
