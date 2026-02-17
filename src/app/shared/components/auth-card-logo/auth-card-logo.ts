import { Component, inject } from '@angular/core';
import { EcopulseLogo } from "../ecopulse-logo/ecopulse-logo";
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

@Component({
  selector: 'app-auth-card-logo',
  imports: [EcopulseLogo],
  templateUrl: './auth-card-logo.html',
})
export class AuthCardLogo {
  
  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 1024px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );
}
