import { CommonModule } from '@angular/common';
import { Component, computed, inject, signal } from '@angular/core';
import { SettingsDataService } from '../../services';
import { ApiService, ConfirmDialogService, HouseholdRole, ToastService, UserAvatar } from '../../../../shared';

@Component({
  selector: 'app-members-admin',
  standalone: true,
  imports: [CommonModule, UserAvatar],
  templateUrl: './members-admin.html',
})
export class MembersAdmin {
  private api = inject(ApiService);
  private confirm = inject(ConfirmDialogService);
  private toast = inject(ToastService);
  readonly data = inject(SettingsDataService);

  readonly isBusy = signal(false);

  readonly myRole = computed<HouseholdRole>(() => this.data.members()?.myRole ?? 'MEMBER');
  readonly rows = computed(() => this.data.members()?.members ?? []);

  readonly canManageRoles = computed(() => {
    const r = this.myRole();
    return r === 'OWNER' || r === 'ADMIN';
  });

  readonly canRemove = computed(() => {
    const r = this.myRole();
    return r === 'OWNER' || r === 'ADMIN';
  });

  roleLabel(role: HouseholdRole) {
    switch (role) {
      case 'OWNER':
        return $localize`:@@role_owner:Owner`;
      case 'ADMIN':
        return $localize`:@@role_admin:Admin`;
      default:
        return $localize`:@@role_member:Member`;
    }
  }

  private roleActionText(role: 'ADMIN' | 'MEMBER') {
    return role === 'ADMIN'
      ? {
        title: $localize`:@@settings_role_upgrade_title:Promote member?`,
        message: $localize`:@@settings_role_upgrade_msg:This will grant admin permissions to this member.`,
        confirmText: $localize`:@@common_promote:Promote`,
        successToast: $localize`:@@settings_role_upgrade_success:Member promoted to admin.`,
        errorToast: $localize`:@@settings_role_upgrade_error:Could not promote member. Please try again.`,
      }
      : {
        title: $localize`:@@settings_role_downgrade_title:Demote member?`,
        message: $localize`:@@settings_role_downgrade_msg:This will remove admin permissions from this member.`,
        confirmText: $localize`:@@common_demote:Demote`,
        successToast: $localize`:@@settings_role_downgrade_success:Member demoted to member.`,
        errorToast: $localize`:@@settings_role_downgrade_error:Could not demote member. Please try again.`,
      };
  }

  async changeRole(userId: string, role: 'ADMIN' | 'MEMBER'): Promise<void> {
    const householdId = this.data.activeHouseholdId();
    if (!householdId) return;

    const t = this.roleActionText(role);

    const ok = await this.confirm.confirm({
      tone: 'danger', // role changes are sensitive; switch to 'neutral' if you prefer
      title: t.title,
      message: t.message,
      cancelText: $localize`:@@common_cancel:Cancel`,
      confirmText: t.confirmText,
    });

    if (!ok) return;

    this.isBusy.set(true);

    this.api.updateMemberRole(householdId, userId, { role }).subscribe({
      next: () => {
        this.isBusy.set(false);
        this.toast.success(t.successToast);
        this.data.reloadForHousehold(householdId);
      },
      error: () => {
        this.isBusy.set(false);
        this.toast.error(t.errorToast);
      },
    });
  }

  async remove(userId: string): Promise<void> {
    const householdId = this.data.activeHouseholdId();
    if (!householdId) return;

    const ok = await this.confirm.confirm({
      tone: 'danger',
      title: $localize`:@@settings_remove_member_title:Remove member?`,
      message: $localize`:@@settings_remove_member_msg:This will remove this member from the household.`,
      cancelText: $localize`:@@common_cancel:Cancel`,
      confirmText: $localize`:@@common_remove:Remove`,
    });

    if (!ok) return;

    this.isBusy.set(true);

    this.api.removeMember(householdId, userId).subscribe({
      next: () => {
        this.isBusy.set(false);
        this.toast.success($localize`:@@settings_remove_member_success:Member removed successfully.`);
        this.data.reloadForHousehold(householdId);
      },
      error: () => {
        this.isBusy.set(false);
        this.toast.error($localize`:@@settings_remove_member_error:Could not remove member. Please try again.`);
      },
    });
  }
}
