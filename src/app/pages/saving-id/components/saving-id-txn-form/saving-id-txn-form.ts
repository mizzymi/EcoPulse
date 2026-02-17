import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormControl, FormGroup, Validators } from '@angular/forms';
import { SavingsTxnType } from '../../../../shared';

@Component({
  selector: 'app-saving-id-txn-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './saving-id-txn-form.html',
})
export class SavingIdTxnForm {
  @Input() busy = false;
  @Output() save = new EventEmitter<{ type: SavingsTxnType; amount: number; note?: string; occursAt?: string | Date }>();

  readonly form = new FormGroup({
    type: new FormControl<SavingsTxnType>('DEPOSIT' as SavingsTxnType, { nonNullable: true }),
    amount: new FormControl<number>(0, { nonNullable: true, validators: [Validators.required, Validators.min(0.01)] }),
    note: new FormControl<string>(''),
    occursAt: new FormControl<string | null>(null),
  });

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const v = this.form.getRawValue();
    this.save.emit({
      type: v.type,
      amount: v.amount,
      note: v.note?.trim() ? v.note.trim() : undefined,
      occursAt: v.occursAt ? new Date(v.occursAt) : undefined,
    });

    this.form.reset({
      type: 'DEPOSIT' as SavingsTxnType,
      amount: 0,
      note: '',
      occursAt: null,
    });
  }
}
