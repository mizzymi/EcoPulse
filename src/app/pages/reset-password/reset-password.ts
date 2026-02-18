import { Component, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { catchError, finalize, of } from 'rxjs';
import { ApiService } from '../../shared';

@Component({
  standalone: true,
  selector: 'app-reset-password-page',
  imports: [CommonModule, RouterModule, ReactiveFormsModule],
  templateUrl: './reset-password.html',
})
export class ResetPassword {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private api = inject(ApiService);

  loading = signal(false);
  error = signal<string | null>(null);
  success = signal(false);

  tokenFromUrl = computed(() => this.route.snapshot.queryParamMap.get('code')?.trim() ?? '');

  needsManualCode = computed(() => !this.tokenFromUrl());

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    password2: ['', [Validators.required]],
    token: [''],
  });

  get mismatch(): boolean {
    const p1 = this.form.value.password ?? '';
    const p2 = this.form.value.password2 ?? '';
    return !!p1 && !!p2 && p1 !== p2;
  }

  submit() {
    this.error.set(null);

    const manualToken = (this.form.value.token ?? '').trim();
    const urlToken = this.tokenFromUrl().trim();

    const code = urlToken || manualToken;

    if (!code) {
      this.error.set('Missing reset code. Please paste the code from your email.');
      return;
    }

    if (this.form.invalid || this.mismatch) {
      this.error.set('Please check the fields.');
      return;
    }

    const email = (this.form.value.email ?? '').trim().toLowerCase();
    const newPassword = (this.form.value.password ?? '').trim();

    this.loading.set(true);

    this.api.resetPassword(email, code, newPassword)
      .pipe(
        finalize(() => this.loading.set(false)),
        catchError((e) => {
          this.error.set(e?.message ?? 'Could not reset password.');
          return of(null);
        })
      )
      .subscribe((res) => {
        if (!res) return;
        this.success.set(true);
        setTimeout(() => this.router.navigate(['/auth/login']), 700);
      });
  }
}
