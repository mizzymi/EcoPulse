import { BreakpointObserver } from '@angular/cdk/layout';
import { Component, inject, input } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { LucideAngularModule, LucideIconData } from 'lucide-angular';
import { map } from 'rxjs';

@Component({
  selector: 'app-nav-options',
  imports: [LucideAngularModule, RouterLink, RouterLinkActive],
  templateUrl: './nav-options.html',
})
export class NavOptions {
  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  isBig = toSignal(
    this.bp.observe('(min-width: 640px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  /** With this property we can get the router link path for this header option. */
  public link = input.required<string>();
  /** With this property we can get the displayed name/label of this header option. */
  public name = input.required<string>();
  /** With this property we can get the displayed icon of this header option. */
  public icon = input.required<LucideIconData>();
}
