import { Component, inject } from '@angular/core';
import {
  BackgroundGadient,
  AuthHero,
  AuthCard,
  AuthOptions,
  AuthCardLogo,
  ToastService,
  ApiService,
  ApiError,
} from '../../shared';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Mail, LockIcon } from 'lucide-angular';
import { Router } from '@angular/router';
import { passwordsMatchValidator } from './passwordsMatchValidator';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [
    BackgroundGadient,
    AuthHero,
    AuthCard,
    AuthCardLogo,
    AuthOptions,
    ReactiveFormsModule,
  ],
  templateUrl: './register.html',
})
export class Register {
  private fb = inject(FormBuilder);
  private toast = inject(ToastService);
  private api = inject(ApiService);
  private router = inject(Router);

  mailIcon = Mail;
  lockIcon = LockIcon;

  form = this.fb.group(
    {
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      password2: ['', [Validators.required]],
    },
    { validators: passwordsMatchValidator }
  );

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const { email, password } = this.form.getRawValue();

    this.api.register(email!, password!).subscribe({
      next: (res) => {
        this.api.setToken(res.accessToken);
        this.toast.success('Registered successfully!');
        this.router.navigate(['/dashboard']);
      },
      error: (err: any) => {
        const status = err?.status ?? err?.statusCode ?? err?.error?.statusCode ?? err?.response?.status;
        const msg =
          err?.message ??
          err?.error?.message ??
          err?.error ??
          'Unexpected error. Try again.';

        this.toast.error(msg);
        if (status === 409) this.toast.error('Email already registered');
      },
    });
  }
}