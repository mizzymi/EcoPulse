import { Component, effect, inject } from '@angular/core';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

import { Container, HouseHoldSelector, LangSwitcher, SelectedHouseholdService } from '../../shared';
import { SavingsFacade } from './data/savings.facade';
import { SavingsGoalsShell } from './components';

@Component({
  selector: 'app-savings',
  standalone: true,
  imports: [Container, HouseHoldSelector, LangSwitcher, SavingsGoalsShell],
  templateUrl: './savings.html',
})
export class Savings {
  private bp = inject(BreakpointObserver);

  readonly household = inject(SelectedHouseholdService);
  readonly facade = inject(SavingsFacade);

  selectedHouseholdId = this.household.selectedHouseholdId;

  isSmall = toSignal(this.bp.observe('(max-width: 1023px)').pipe(map((r) => r.matches)), { initialValue: false });

  constructor() {
    effect(() => {
      const id = this.selectedHouseholdId();
      this.facade.householdId.set(id ?? null);
      this.facade.refresh();
    });
  }
}
