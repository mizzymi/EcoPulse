import { Component, computed, inject, Input, signal } from '@angular/core';
import { BreakpointObserver } from '@angular/cdk/layout';
import { House, LucideAngularModule, PiggyBank, Plus, ReceiptText, Settings } from 'lucide-angular';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs/operators';
import { NavOptions } from '../nav-options/nav-options';

@Component({
  selector: 'app-bottom-nav-bar',
  imports: [LucideAngularModule, NavOptions],
  templateUrl: './bottom-nav-bar.html',
})
export class BottomNavBar {
  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  readonly plus = Plus;
  readonly home = House;
  readonly settings = Settings;
  readonly history = ReceiptText;
  readonly savings = PiggyBank;
}
