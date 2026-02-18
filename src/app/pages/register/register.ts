import { Component, inject } from '@angular/core';
import {
  BackgroundGadient,
  AuthHero,
  AuthCard,
  AuthOptions,
  AuthCardLogo,
  ToastService,
  ApiService,
} from '../../shared';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Mail, LockIcon, User as UserIcon } from 'lucide-angular';
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
  userIcon = UserIcon;

  form = this.fb.group(
    {
      username: [
        '',
        [
          Validators.required,
          Validators.minLength(3),
          Validators.maxLength(24),
          Validators.pattern(/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/),
        ],
      ],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6), Validators.maxLength(72)]],
      password2: ['', [Validators.required]],
    },
    { validators: passwordsMatchValidator }
  );

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const { email, password, username } = this.form.getRawValue();

    this.api.register(email!, password!, username!).subscribe({
      next: (res) => {
        this.api.setToken(res.accessToken);
        this.toast.success($localize`:@@auth.register.toastSuccess:Registered successfully!`);
        this.router.navigate(['/dashboard']);
      },
      error: (err: any) => {
        const status =
          err?.status ?? err?.statusCode ?? err?.error?.statusCode ?? err?.response?.status;

        const msg =
          err?.message ??
          err?.error?.message ??
          err?.error ??
          $localize`:@@common.unexpectedError:Unexpected error. Try again.`;

        // Prefer specific errors
        if (status === 409) {
          this.toast.error($localize`:@@auth.register.emailConflict:Email already registered`);
          return;
        }
        if (status === 400) {
          this.toast.error($localize`:@@auth.register.badRequest:Check the form fields and try again`);
          return;
        }

        this.toast.error(msg);
      },
    });
  }

  // Small helpers (optional but clean for template)
  get u() { return this.form.controls.username; }
  get e() { return this.form.controls.email; }
  get p1() { return this.form.controls.password; }
  get p2() { return this.form.controls.password2; }
}
