import { BreakpointObserver } from '@angular/cdk/layout';
import { Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ChartPie, House, LucideAngularModule, PiggyBank, ReceiptText, Settings, Target } from 'lucide-angular';
import { map } from 'rxjs';
import { NavOptions } from '../nav-options/nav-options';
import { EcopulseNameLogo } from "../../ecopulse-name-logo/ecopulse-name-logo";
import { HouseHoldMembers } from "../../house-hold-members/house-hold-members";

@Component({
  selector: 'app-aside-nav-bar',
  imports: [LucideAngularModule, NavOptions, EcopulseNameLogo, HouseHoldMembers],
  templateUrl: './aside-nav-bar.html',
})
export class AsideNavBar {

  private bp = inject(BreakpointObserver);

  isBig = toSignal(
    this.bp.observe('(min-width: 640px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  readonly home = House;
  readonly history = ReceiptText;
  readonly chart = ChartPie;
  readonly goals = Target;
  readonly savings = PiggyBank;
  readonly settings = Settings;

  private _householdId = signal<string | null>(null);

  hId = computed(() => this._householdId());

  link = computed(() => {
    const id = this.hId();

    return {
      dashboard: id ? ['/dashboard', id] : ['/dashboard'],
      chart: id ? ['/chart', id] : ['/chart'],
      goals: id ? ['/goals', id] : ['/goals'],
      savings: id ? ['/savings', id] : ['/savings'],
      settings: id ? ['/settings', id] : ['/settings'],
    };
  });
}
