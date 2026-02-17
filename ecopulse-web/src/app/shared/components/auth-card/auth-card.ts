import { Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-auth-card',
  imports: [RouterLink],
  templateUrl: './auth-card.html',
})
export class AuthCard {
  public title = input.required<string>()
  public quote = input.required<string>()

  public isLogin = input.required<boolean>()
  public isRegister = input.required<boolean>()
}
