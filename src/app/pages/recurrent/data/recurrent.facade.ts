import { Injectable, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ApiService, LedgerEntryType, PlannedItemDto, RecurringDefDto, SelectedHouseholdService } from '../../../shared';
import {
    OkResponseDto,
    PostRecurringInstanceResponseDto,
} from './recurrent.models';

function toYYYYMM(d = new Date()): string {
    const y = d.getFullYear();
    const m = d.getMonth() + 1;
    return `${y}-${m < 10 ? '0' + m : m}`;
}

@Injectable({ providedIn: 'root' })
export class RecurrentFacade {
    private api = inject(ApiService);
    private household = inject(SelectedHouseholdService);

    // UI state
    readonly month = signal<string>(toYYYYMM());
    readonly type = signal<LedgerEntryType | ''>('');
    readonly category = signal<string>('');
    readonly accountType = signal<string>('');

    readonly isLoadingPlanned = signal(false);
    readonly isLoadingRecurring = signal(false);

    readonly planned = signal<PlannedItemDto[]>([]);
    readonly recurring = signal<RecurringDefDto[]>([]);

    readonly selectedHouseholdId = this.household.selectedHouseholdId;

    readonly plannedTotals = computed(() => {
        const rows = this.planned();
        const income = rows.filter((r) => r.type === 'INCOME').reduce((a, b) => a + (Number(b.amount) || 0), 0);
        const expense = rows.filter((r) => r.type === 'EXPENSE').reduce((a, b) => a + (Number(b.amount) || 0), 0);
        return { income, expense, net: income - expense };
    });

    readonly recurringTotals = computed(() => {
        const rows = this.recurring();
        const income = rows.filter((r) => r.type === 'INCOME').reduce((a, b) => a + (Number(b.amount) || 0), 0);
        const expense = rows.filter((r) => r.type === 'EXPENSE').reduce((a, b) => a + (Number(b.amount) || 0), 0);
        return { income, expense, net: income - expense };
    });

    refreshPlanned(): void {
        const hid = this.selectedHouseholdId();
        if (!hid) return;

        this.isLoadingPlanned.set(true);

        const q = {
            month: this.month(),
            type: this.type() || undefined,
            category: this.category() || undefined,
            accountType: this.accountType() || undefined,
        };

        this.api
            .listPlanned(hid, q)
            .pipe(finalize(() => this.isLoadingPlanned.set(false)))
            .subscribe({
                next: (rows) => this.planned.set(rows ?? []),
                error: () => this.planned.set([]),
            });
    }

    refreshRecurring(): void {
        const hid = this.selectedHouseholdId();
        if (!hid) return;

        this.isLoadingRecurring.set(true);

        const q = {
            month: this.month(),
            type: this.type() || undefined,
            category: this.category() || undefined,
            accountType: this.accountType() || undefined,
        };

        this.api
            .listRecurring(hid, q)
            .pipe(finalize(() => this.isLoadingRecurring.set(false)))
            .subscribe({
                next: (rows) => this.recurring.set(rows ?? []),
                error: () => this.recurring.set([]),
            });
    }

    createPlanned(dto: {
        concept: string;
        amount: number | string;
        type: LedgerEntryType;
        dueDate: string;
        month?: string;
        notes?: string;
        category?: string;
        accountType?: unknown;
    }): Observable<PlannedItemDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.createPlanned(hid, dto);
    }

    updatePlanned(plannedId: string, dto: any): Observable<PlannedItemDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.updatePlanned(hid, plannedId, dto);
    }

    deletePlanned(plannedId: string): Observable<OkResponseDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.deletePlanned(hid, plannedId);
    }

    settlePlanned(plannedId: string): Observable<{ ok: true } | { ok: true; alreadySettled: true }> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.settlePlanned(hid, plannedId);
    }

    createRecurring(dto: {
        concept: string;
        amount: number | string;
        type: LedgerEntryType;
        dayOfMonth?: number;
        rrule?: string;
        notes?: string;
        category?: string;
        accountType?: unknown;
    }): Observable<RecurringDefDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.createRecurring(hid, dto);
    }

    updateRecurring(recurringId: string, dto: any): Observable<RecurringDefDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.updateRecurring(hid, recurringId, dto);
    }

    deleteRecurring(recurringId: string): Observable<OkResponseDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.deleteRecurring(hid, recurringId);
    }

    postRecurring(recurringId: string, dto?: { month?: string; occursAt?: string | Date }): Observable<PostRecurringInstanceResponseDto> {
        const hid = this.selectedHouseholdId();
        if (!hid) throw new Error('No household selected');
        return this.api.postRecurringInstance(hid, recurringId, dto);
    }
}
