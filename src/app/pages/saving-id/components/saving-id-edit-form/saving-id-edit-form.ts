import { Component, EventEmitter, Input, Output, effect, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl, FormGroup, Validators } from '@angular/forms';
import { SavingsGoalDto } from '../../../../shared';

@Component({
  selector: 'app-saving-id-edit-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './saving-id-edit-form.html',
})
export class SavingIdEditForm {
  @Input() goal: SavingsGoalDto | undefined;
  @Input() busy = false;

  @Output() save = new EventEmitter<{ name?: string; target?: number; deadline?: string | Date | null }>();
  @Output() delete = new EventEmitter<void>();

  readonly form = new FormGroup({
    name: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    target: new FormControl<number>(0, { nonNullable: true, validators: [Validators.required, Validators.min(0)] }),
    deadline: new FormControl<string | null>(null),
  });

  constructor() {
    effect(() => {
      const g = this.goal;
      if (!g) return;

      this.form.patchValue(
        {
          name: g.name ?? '',
          target: Number(g.target ?? 0),
          deadline: g.deadline ? this.toDateInputValue(g.deadline) : null,
        },
        { emitEvent: false },
      );
    });
  }

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const v = this.form.getRawValue();
    this.save.emit({
      name: v.name,
      target: v.target,
      deadline: v.deadline ? new Date(v.deadline) : null,
    });
  }

  private toDateInputValue(value: string | Date): string | null {
    const d = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(d.getTime())) return null;
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }
}
