import { Component, inject } from '@angular/core';
import { BackgroundGadient, AuthHero, AuthCard, AuthOptions, AuthCardLogo, ToastService, ApiService, ApiError } from '../../shared';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Mail, LockIcon } from 'lucide-angular';
import { ForgotPasswordModal } from './components';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    BackgroundGadient,
    AuthHero,
    AuthCard,
    AuthCardLogo,
    AuthOptions,
    ReactiveFormsModule,
    ForgotPasswordModal,
    RouterLink
  ],
  templateUrl: './login.html',
})
export class Login {
  private fb = inject(FormBuilder);
  private toast = inject(ToastService);
  private api = inject(ApiService);
  private router = inject(Router);

  mailIcon = Mail;
  lockIcon = LockIcon;

  forgotOpen = false;

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required]],
  });

  openForgot() {
    this.forgotOpen = true;
  }

  closeForgot() {
    this.forgotOpen = false;
  }

  handleForgotEmail(email: string) {
    this.api.requestPasswordReset(email).subscribe({
      next: () => {
        this.toast.success('Recovery email sent!');
        this.forgotOpen = false;
      },
      error: (e) => {
        console.error("Reset error:", e);
        this.toast.error(e?.message ?? `Status: ${e?.status}`);
      },
    });
  }

  submit() {
    if (this.form.invalid) return;

    const { email, password } = this.form.getRawValue();

    this.api.login(email!, password!).subscribe({
      next: (res) => {
        this.api.setToken(res.accessToken);
        this.toast.success('Logged in!');
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
          this.toast.error('Wrong credentials');
          return;
        }
        this.toast.error('Unexpected error. Try again.');
      },
    });
  }
}
