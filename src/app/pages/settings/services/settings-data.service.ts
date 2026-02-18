import { Injectable, computed, effect, inject, signal } from '@angular/core';
import { HouseholdContextService } from './household-context.service';

import {
    ApiService,
    HouseholdListItemDto,
    InviteCreateResponseDto,
    MembersListDto,
    MonthlySummaryDto,
    SavingsGoalDto,
} from '../../../shared';
import { Observable, of, switchMap, tap, map, catchError } from 'rxjs';

export type ViewState = 'idle' | 'loading' | 'ready' | 'error';

@Injectable()
export class SettingsDataService {
    private api = inject(ApiService);
    private ctx = inject(HouseholdContextService);

    readonly state = signal<ViewState>('idle');
    readonly error = signal<string | null>(null);

    readonly households = signal<HouseholdListItemDto[]>([]);
    readonly members = signal<MembersListDto | null>(null);
    readonly invite = signal<InviteCreateResponseDto | null>(null);

    // ✅ NEW: finance data
    readonly monthSummary = signal<MonthlySummaryDto | null>(null);
    readonly savingsGoals = signal<SavingsGoalDto[]>([]);

    /** Selected household (signal from SelectedHouseholdService) */
    readonly activeHouseholdId = computed(() => this.ctx.selectedHouseholdId());

    readonly activeHousehold = computed(() => {
        const id = this.activeHouseholdId();
        return this.households().find(h => h.id === id) ?? null;
    });

    readonly memberCount = computed(() => this.members()?.members?.length ?? 0);

    // ✅ NEW: computed balances
    readonly currentBalance = computed(() => this.monthSummary()?.closingBalance ?? 0);

    readonly totalSaved = computed(() =>
        (this.savingsGoals() ?? []).reduce((acc, g) => acc + (g.saved ?? 0), 0),
    );

    /** What you want to show in the big number */
    readonly displayBalance = computed(() => this.currentBalance() + this.totalSaved());

    private lastLoadedHouseholdId: string | null = null;

    constructor() {
        effect(() => {
            const id = this.activeHouseholdId();
            if (!id) return;

            if (this.households().length === 0) return;
            if (this.lastLoadedHouseholdId === id) return;

            this.lastLoadedHouseholdId = id;
            this.reloadForHousehold(id);
        });
    }

    init() {
        this.state.set('loading');
        this.error.set(null);

        this.api.myHouseholds().subscribe({
            next: (rows) => {
                this.households.set(rows ?? []);
                this.state.set('ready');
            },
            error: (e: any) => {
                this.state.set('error');
                this.error.set(e?.message ?? 'Failed to load households');
            },
        });
    }

    reloadForHousehold(householdId: string) {
        this.state.set('loading');
        this.error.set(null);

        this.members.set(null);
        this.invite.set(null);

        // ✅ reset finance data
        this.monthSummary.set(null);
        this.savingsGoals.set([]);

        // Members
        this.api.listMembers(householdId).subscribe({
            next: (m) => {
                this.members.set(m);
                this.state.set('ready');
            },
            error: (e: any) => {
                this.state.set('error');
                this.error.set(e?.message ?? 'Failed to load members');
            },
        });

        // Invite (best-effort)
        this.api
            .createInvite(householdId, { expiresInHours: 2, maxUses: 1, requireApproval: true })
            .subscribe({
                next: (inv) => this.invite.set(inv),
                error: () => this.invite.set(null),
            });

        // ✅ Monthly summary (closingBalance)
        const month = this.getCurrentMonthYYYYMM();
        this.api.monthlySummary(householdId, month).subscribe({
            next: (s) => this.monthSummary.set(s),
            error: () => this.monthSummary.set(null), // non-blocking
        });

        // ✅ Savings goals (sum saved)
        this.api.listSavingsGoals(householdId).subscribe({
            next: (goals) => this.savingsGoals.set(goals ?? []),
            error: () => this.savingsGoals.set([]), // non-blocking
        });
    }

    newInvite() {
        const id = this.activeHouseholdId();
        if (!id) return;

        this.api
            .createInvite(id, { expiresInHours: 2, maxUses: 1, requireApproval: true })
            .subscribe({
                next: (inv) => this.invite.set(inv),
                error: (e: any) => this.error.set(e?.message ?? 'Failed to create invite'),
            });
    }

    deleteHousehold(): Observable<boolean> {
        const id = this.activeHouseholdId();
        if (!id) return of(false);

        this.state.set('loading');
        this.error.set(null);

        return this.api.deleteHousehold(id).pipe(
            switchMap(() => this.api.myHouseholds()),
            tap((rows) => {
                this.households.set(rows ?? []);
                this.state.set('ready');
                this.lastLoadedHouseholdId = null;
                this.members.set(null);
                this.invite.set(null);
                this.monthSummary?.set?.(null);
                this.savingsGoals?.set?.([]);
            }),
            map(() => true),
            catchError((e: any) => {
                this.state.set('error');
                this.error.set(e?.message ?? 'Failed to delete household');
                return of(false);
            }),
        );
    }

    copyInviteCodeToClipboard(code: string) {
        if (!code) return;
        navigator.clipboard?.writeText(code).catch(() => { });
    }

    private getCurrentMonthYYYYMM(): string {
        const d = new Date();
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        return `${y}-${m}`;
    }
}
