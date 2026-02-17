import { Component, computed, forwardRef, input, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ControlValueAccessor, NG_VALUE_ACCESSOR, ReactiveFormsModule } from '@angular/forms';
import { LucideAngularModule, LucideIconData, Eye, EyeOff } from 'lucide-angular';

@Component({
  selector: 'app-auth-options',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, LucideAngularModule],
  templateUrl: './auth-options.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => AuthOptions),
      multi: true,
    },
  ],
})
export class AuthOptions implements ControlValueAccessor {
  public label = input.required<string>();
  public placeholder = input.required<string>();
  public inputType = input.required<string>();
  public id = input.required<string>();

  public leadingIcon = input<LucideIconData | null>(null);
  public showPasswordToggle = input<boolean>(false);

  // icons for the eye button
  public eyeIcon: LucideIconData = Eye;
  public eyeOffIcon: LucideIconData = EyeOff;

  public value = '';
  public disabled = false;

  private onChange: (v: string) => void = () => { };
  private onTouched: () => void = () => { };

  private _passwordVisible = signal(false);
  public isPasswordVisible = computed(() => this._passwordVisible());

  public actualType = computed(() => {
    const t = this.inputType();
    if (t !== 'password') return t;
    return this.isPasswordVisible() ? 'text' : 'password';
  });

  togglePasswordVisibility() {
    if (this.inputType() !== 'password') return;
    this._passwordVisible.update((v) => !v);
  }

  writeValue(v: string | null): void {
    this.value = v ?? '';
  }

  registerOnChange(fn: (v: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  handleInput(next: string) {
    this.value = next;
    this.onChange(next);
  }

  handleBlur() {
    this.onTouched();
  }
}
