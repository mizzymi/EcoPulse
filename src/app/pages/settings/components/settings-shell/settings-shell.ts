import { Component, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SettingsDataService } from '../../services';
import { HouseholdSummaryCard } from '../household-summary-card/household-summary-card';
import { ManagementActions } from '../management-actions/management-actions';
import { SettingsTabs } from '../settings-tabs/settings-tabs';
import { SettingsTabsService } from '../../services/settings-tabs.service';

@Component({
  selector: 'app-settings-shell',
  standalone: true,
  imports: [CommonModule, HouseholdSummaryCard, ManagementActions, SettingsTabs],
  templateUrl: './settings-shell.html',
  providers: [SettingsTabsService],
})
export class SettingsShell {
  readonly data = inject(SettingsDataService);

  readonly isLoading = computed(() => this.data.state() === 'loading');
  readonly isError = computed(() => this.data.state() === 'error');
}
