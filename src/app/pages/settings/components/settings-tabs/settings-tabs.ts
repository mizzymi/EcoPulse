import { CommonModule } from '@angular/common';
import { Component, computed, inject } from '@angular/core';
import { ActiveInviteCard } from '../active-invite-card/active-invite-card';
import { MembersAdmin } from '../members-admin/members-admin';
import { SettingsTabsService } from '../../services/settings-tabs.service';

@Component({
  selector: 'app-settings-tabs',
  standalone: true,
  imports: [CommonModule, ActiveInviteCard, MembersAdmin],
  templateUrl: './settings-tabs.html',
})
export class SettingsTabs {
  private tabs = inject(SettingsTabsService);

  readonly tab = this.tabs.tab;

  readonly isInvite = computed(() => this.tab() === 'invite');
  readonly isMembers = computed(() => this.tab() === 'members');

  setTab(t: 'invite' | 'members') {
    this.tabs.setTab(t);
  }
}
