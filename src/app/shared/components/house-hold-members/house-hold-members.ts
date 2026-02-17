import {
  Component,
  inject,
  signal,
  computed,
  DestroyRef,
} from '@angular/core';
import { NgFor, NgIf, NgStyle } from '@angular/common';
import { switchMap, of, catchError, tap } from 'rxjs';
import { toSignal, toObservable } from '@angular/core/rxjs-interop';
import { ApiService, MembersListDto, SelectedHouseholdService } from '../../services';
import { UserAvatar } from '../user-avatar/user-avatar';

type MemberVM = {
  id: string;        // used for gradient
  role: string;
  isMe: boolean;
};

@Component({
  selector: 'app-house-hold-members',
  standalone: true,
  imports: [NgIf, NgFor, UserAvatar, NgStyle],
  templateUrl: './house-hold-members.html',
})
export class HouseHoldMembers {
  private api = inject(ApiService);
  private selected = inject(SelectedHouseholdService);
  private destroyRef = inject(DestroyRef);

  // Config like your screenshot (2 avatars + bubble)
  maxVisible = 2;

  // UI state
  loading = signal(false);
  error = signal<string | null>(null);

  // Shared selected household id (Signal<string | null>)
  householdId = this.selected.selectedHouseholdId;
  private householdId$ = toObservable(this.householdId);

  // Load members whenever household changes
  private membersResponse = toSignal<MembersListDto | null>(
    this.householdId$.pipe(
      tap(() => {
        this.loading.set(true);
        this.error.set(null);
      }),
      switchMap((id) => {
        if (!id) {
          this.loading.set(false);
          return of<MembersListDto | null>(null);
        }

        return this.api.listMembers(id).pipe(
          tap(() => this.loading.set(false)),
          catchError((e: any) => {
            this.loading.set(false);
            this.error.set(e?.message ?? 'Failed to load members');
            return of<MembersListDto | null>(null);
          })
        );
      })
    ),
    { initialValue: null }
  );

  // View model
  members = computed<MemberVM[]>(() => {
    const res = this.membersResponse();
    if (!res) return [];

    return (res.members ?? []).map((m) => ({
      // Use user.id for gradient seed (recommended)
      id: m.user?.id ?? m.userId,
      role: m.role,
      isMe: m.isMe,
    }));
  });

  visibleMembers = computed(() => this.members().slice(0, this.maxVisible));
  extraCount = computed(() => Math.max(0, this.members().length - this.maxVisible));


  public mapError(code: string): string {
    switch (code) {
      case 'NETWORK':
        return $localize`:@@sharedMembers.error.network:Network error. Try again.`;
      case 'UNAUTHORIZED':
        return $localize`:@@sharedMembers.error.unauthorized:Session expired. Please sign in again.`;
      default:
        return $localize`:@@sharedMembers.error.unknown:Something went wrong.`;
    }
  }
}
