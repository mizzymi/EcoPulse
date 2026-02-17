import { Component, EventEmitter, HostListener, Output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

@Component({
  selector: 'app-forgot-password-modal',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './forgot-password-modal.html',
})
export class ForgotPasswordModal {
  private fb = inject(FormBuilder);

  @Output() close = new EventEmitter<void>();
  @Output() submitEmail = new EventEmitter<string>();

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
  });

  @HostListener('document:keydown.escape')
  onEsc() {
    this.close.emit();
  }

  onBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) this.close.emit();
  }

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.submitEmail.emit(this.form.value.email!);
  }
}
