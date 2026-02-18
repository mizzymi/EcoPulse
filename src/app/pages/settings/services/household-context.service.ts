import { inject, Injectable} from '@angular/core';
import { SelectedHouseholdService } from '../../../shared';

const KEY = 'activeHouseholdId';

@Injectable({ providedIn: 'root' })
export class HouseholdContextService {
    readonly household = inject(SelectedHouseholdService);
    selectedHouseholdId = this.household.selectedHouseholdId;
}
