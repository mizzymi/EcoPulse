import { Component, inject } from '@angular/core';
import { Container, HouseHoldSelector, SelectedHouseholdService } from '../../shared';
import { FinancialOverviewPage } from './components';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

@Component({
  selector: 'app-dashboard',
  imports: [Container, FinancialOverviewPage, HouseHoldSelector],
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
}
