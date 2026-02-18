import { Component, effect, inject } from '@angular/core';
import { ApiService, Container, HouseHoldSelector, LangSwitcher, SelectedHouseholdService, ToastService } from '../../shared';
import { FinancialOverviewPage } from './components';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';
import { HouseholdContextService } from '../settings/services';

@Component({
  selector: 'app-dashboard',
  imports: [Container, FinancialOverviewPage, HouseHoldSelector, LangSwitcher],
  templateUrl: './dashboard.html',
})
export class Dashboard {
  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  readonly household = inject(SelectedHouseholdService);
  selectedHouseholdId = this.household.selectedHouseholdId;

  private api = inject(ApiService);
  private toast = inject(ToastService);
  private ctx = inject(HouseholdContextService);

  constructor() {
    effect(() => {
      const householdId = this.ctx.selectedHouseholdId();
      if (!householdId) return;

      this.api.autoPostRecurringToday(householdId).subscribe(({ posted }) => {
        if (posted > 0) {
          this.toast.success(
            $localize`:@@recurring_autopost_done:Recurring entries added: ${posted}:posted:`
          );
        }
      });
    });
  }
}
