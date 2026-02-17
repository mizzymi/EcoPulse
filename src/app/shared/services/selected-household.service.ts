import { Injectable, signal, computed, effect } from '@angular/core';

const KEY = 'selected_household_id';

@Injectable({ providedIn: 'root' })
export class SelectedHouseholdService {
    readonly selectedHouseholdId = signal<string | null>(localStorage.getItem(KEY));

    readonly hasSelection = computed(() => this.selectedHouseholdId() !== null);

    constructor() {
        effect(() => {
            const id = this.selectedHouseholdId();
            if (id) localStorage.setItem(KEY, id);
            else localStorage.removeItem(KEY);
        });
    }

    setHousehold(id: string | null) {
        this.selectedHouseholdId.set(id);
    }
}
