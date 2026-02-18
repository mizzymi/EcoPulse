import { CommonModule, CurrencyPipe, DatePipe } from '@angular/common';
import { Component, computed, inject } from '@angular/core';
import { SettingsDataService } from '../../services';
import { MembersAvatars } from '../members-avatars/members-avatars';

@Component({
  selector: 'app-household-summary-card',
  standalone: true,
  imports: [CommonModule, CurrencyPipe, DatePipe, MembersAvatars],
  templateUrl: './household-summary-card.html',
})
export class HouseholdSummaryCard {
  readonly data = inject(SettingsDataService);

  readonly household = computed(() => this.data.activeHousehold());
  readonly displayBalance = computed(() => this.data.displayBalance());
  readonly memberCount = computed(() => this.data.memberCount());

  // Optional: if you want breakdown in UI later
  readonly currentBalance = computed(() => this.data.currentBalance());
  readonly totalSaved = computed(() => this.data.totalSaved());
}
