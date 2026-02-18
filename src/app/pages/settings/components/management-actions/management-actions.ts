import { CommonModule } from '@angular/common';
import { Component, computed, inject } from '@angular/core';
import { Router } from '@angular/router';
import { SettingsDataService } from '../../services';
import { ApiService, ConfirmDialogService, ToastService } from '../../../../shared';
import { SettingsTabsService } from '../../services/settings-tabs.service';

@Component({
  selector: 'app-management-actions',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './management-actions.html',
})
export class ManagementActions {
  readonly api = inject(ApiService);
  readonly data = inject(SettingsDataService);

  private confirm = inject(ConfirmDialogService);
  private tabs = inject(SettingsTabsService);
  private toast = inject(ToastService);
  private router = inject(Router);

  readonly canDelete = computed(() => this.data.members()?.myRole === 'OWNER');

  onInvite() {
    this.tabs.setTab('invite');
    this.data.newInvite();
  }

  onSeeMembers() {
    this.tabs.setTab('members');
  }

  logOut() {
    this.api.logout();
  }

  async onDelete() {
    if (!this.canDelete()) return;

    const householdName = this.data.activeHousehold()?.name ?? '';

    const ok = await this.confirm.confirm({
      tone: 'danger',
      title: $localize`:@@settings_delete_modal_title:Delete account?`,
      message: householdName
        ? $localize`:@@settings_delete_modal_msg_named:This will permanently delete "${householdName}". This action cannot be undone.`
        : $localize`:@@settings_delete_modal_msg:This will permanently delete this account. This action cannot be undone.`,
      cancelText: $localize`:@@common_cancel:Cancel`,
      confirmText: $localize`:@@common_delete:Delete`,
    });

    if (!ok) return;

    this.data.deleteHousehold().subscribe((success) => {
      if (!success) return;

      this.toast.success(
        $localize`:@@settings_delete_success:Account deleted successfully!`
      );

      this.router.navigate(['/dashboard']);
    });
  }
}
