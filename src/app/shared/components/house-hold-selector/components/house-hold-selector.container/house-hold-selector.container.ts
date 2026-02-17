import {
  Component,
  DestroyRef,
  HostListener,
  inject,
  signal,
  computed,
} from '@angular/core';
import { NgIf } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { ApiService, HouseholdListItemDto, SelectedHouseholdService } from '../../../../services';
import { toInitials } from '../../hh-initials.util';
import { HhSelectorTrigger } from '../hh-selector-trigger/hh-selector-trigger';
import { HhSelectorDropdown } from '../hh-selector-dropdown/hh-selector-dropdown';

@Component({
  selector: 'app-house-hold-selector-container',
  standalone: true,
  imports: [NgIf, HhSelectorTrigger, HhSelectorDropdown],
  templateUrl: './house-hold-selector.container.html',
})
export class HouseHoldSelectorContainer {
  private api = inject(ApiService);
  private selected = inject(SelectedHouseholdService);
  private destroyRef = inject(DestroyRef);

  // UI state
  open = signal(false);
  creating = signal(false);

  // Data state
  households = signal<HouseholdListItemDto[]>([]);
  loading = signal(false);
  error = signal<string | null>(null);

  // Create form
  newName = signal('');
  newCurrency = signal('EUR');
  creatingBusy = signal(false);
  createError = signal<string | null>(null);

  // Shared selection
  selectedId = this.selected.selectedHouseholdId;

  selectedHousehold = computed(() => {
    const list = this.households();
    const id = this.selectedId();
    return list.find(h => h.id === id) ?? list[0] ?? null;
  });

  initials = computed(() => {
    const name = (this.selectedHousehold()?.name ?? '').trim();
    if (name.length >= 2) return name.slice(0, 2).toUpperCase();
    if (name.length === 1) return name[0].toUpperCase();

    return 'HW';
  });

  roleLabel = computed(() => {
    const r = this.selectedHousehold()?.role;
    return r === 'OWNER' ? 'Owner' : r === 'ADMIN' ? 'Admin' : 'Member';
  });

  constructor() {
    this.refresh();
  }

  refresh() {
    this.loading.set(true);
    this.error.set(null);

    this.api
      .myHouseholds()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (rows) => {
          const list = rows ?? [];
          this.households.set(list);
          this.loading.set(false);

          // If nothing selected or selection is not in the list, select first
          const current = this.selectedId();
          const exists = current ? list.some(h => h.id === current) : false;
          if ((!current || !exists) && list.length) {
            this.select(list[0]);
          }
        },
        error: (e: any) => {
          this.loading.set(false);
          this.error.set(e?.message ?? 'Failed to load households');
        },
      });
  }

  toggle() {
    if (this.loading()) return;
    this.open.set(!this.open());
    if (!this.open()) this.resetCreate();
  }

  close() {
    this.open.set(false);
    this.resetCreate();
  }

  select(h: HouseholdListItemDto) {
    this.selected.setHousehold(h.id);
    this.close();
  }

  startCreate() {
    this.creating.set(true);
    this.createError.set(null);
    if (!this.newName().trim()) this.newName.set('');
  }

  cancelCreate() {
    this.resetCreate();
  }

  createHousehold() {
    const name = this.newName().trim();
    const currency = this.newCurrency().trim().toUpperCase() || 'EUR';

    if (!name) {
      this.createError.set('Name is required');
      return;
    }

    this.creatingBusy.set(true);
    this.createError.set(null);

    this.api
      .createHousehold(name, currency)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: () => {
          this.creatingBusy.set(false);
          this.resetCreate();

          // Reload list and select the newest (assuming BE returns newest first)
          this.api
            .myHouseholds()
            .pipe(takeUntilDestroyed(this.destroyRef))
            .subscribe({
              next: (rows) => {
                const list = rows ?? [];
                this.households.set(list);
                if (list[0]) this.select(list[0]);
                else this.close();
              },
              error: () => this.close(),
            });
        },
        error: (e: any) => {
          this.creatingBusy.set(false);
          this.createError.set(e?.message ?? 'Failed to create household');
        },
      });
  }

  onNameChange(v: string) {
    this.newName.set(v);
  }

  onCurrencyChange(v: string) {
    this.newCurrency.set(v);
  }

  private resetCreate() {
    this.creating.set(false);
    this.creatingBusy.set(false);
    this.createError.set(null);
    this.newName.set('');
    this.newCurrency.set('EUR');
  }

  /** Close dropdown on ESC */
  @HostListener('document:keydown.escape')
  onEsc() {
    if (this.open()) this.close();
  }

  /** Close dropdown on outside click */
  @HostListener('document:click', ['$event'])
  onDocClick(ev: MouseEvent) {
    if (!this.open()) return;
    const target = ev.target as HTMLElement | null;
    if (!target) return;

    // "Good enough" selector approach (you can improve using ElementRef)
    const host = document.querySelector('app-house-hold-selector');
    if (host && host.contains(target)) return;

    this.close();
  }
}
