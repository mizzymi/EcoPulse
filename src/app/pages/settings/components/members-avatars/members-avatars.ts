import { CommonModule } from '@angular/common';
import { Component, computed, inject } from '@angular/core';
import { SettingsDataService } from '../../services';
import { UserAvatar } from '../../../../shared';

@Component({
  selector: 'app-members-avatars',
  imports: [CommonModule, UserAvatar],
  templateUrl: './members-avatars.html',
})
export class MembersAvatars {
  readonly data = inject(SettingsDataService);

  readonly members = computed(() => this.data.members()?.members ?? []);
  readonly shown = computed(() => this.members().slice(0, 3));
  readonly extra = computed(() => Math.max(0, this.members().length - this.shown().length));
}
