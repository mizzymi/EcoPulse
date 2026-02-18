import { Component, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SettingsDataService } from '../../services';

@Component({
  selector: 'app-active-invite-card',
  imports: [CommonModule],
  templateUrl: './active-invite-card.html',
})
export class ActiveInviteCard {
  readonly data = inject(SettingsDataService);

  readonly invite = computed(() => this.data.invite());
  readonly code = computed(() => this.invite()?.code ?? '');
  readonly expiresAt = computed(() => this.invite()?.expiresAt ?? null);

  copy() {
    this.data.copyInviteCodeToClipboard(this.code());
  }
}
