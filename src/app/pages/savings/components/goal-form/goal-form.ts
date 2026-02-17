import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SavingsFacade } from '../../data/savings.facade';

@Component({
  selector: 'app-goal-form',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './goal-form.html',
})
export class GoalForm {
  readonly facade = inject(SavingsFacade);

  name = signal('');
  target = signal<number | null>(null);
  deadline = signal<string>('');

  submitting = signal(false);
  error = signal<string | null>(null);
  success = signal(false);

  canSubmit() {
    return !!this.facade.householdId() && this.name().trim().length >= 2 && !!this.target() && (this.target() as number) > 0;
  }

  submit() {
    this.error.set(null);
    this.success.set(false);

    if (!this.canSubmit()) {
      this.error.set('Missing required fields.');
      return;
    }

    this.submitting.set(true);

    const dto = {
      name: this.name().trim(),
      target: Number(this.target()),
      deadline: this.deadline() ? new Date(this.deadline()) : undefined,
    };

    this.facade.createGoal(dto).subscribe({
      next: () => {
        this.name.set('');
        this.target.set(null);
        this.deadline.set('');
        this.success.set(true);
        this.submitting.set(false);
      },
      error: (e: any) => {
        this.error.set(e?.message ?? 'Failed to create goal');
        this.submitting.set(false);
      },
    });
  }
  
  parseNumber(value: any): number | null {
    if (value === '' || value === null || value === undefined) return null;
    const n = typeof value === 'number' ? value : Number(String(value));
    return Number.isFinite(n) ? n : null;
  }
}
