import { DestroyRef, computed, effect, inject, Injectable, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ApiService, LedgerEntryDto, LedgerEntryType, SelectedHouseholdService, TransactionRow } from '../../../shared';
import { mapLedgerEntriesToRows } from './history.mapper';

@Injectable()
export class HistoryFacade {
    private api = inject(ApiService);
    private destroyRef = inject(DestroyRef);
    private householdSvc = inject(SelectedHouseholdService);

    // selected household id (signal from shared service)
    readonly selectedHouseholdId = this.householdSvc.selectedHouseholdId;

    // UI state
    readonly loading = signal(false);
    readonly error = signal<string | null>(null);

    // filters (API-supported)
    readonly from = signal<string | null>(null);
    readonly to = signal<string | null>(null);
    readonly limit = signal<number>(200);
    readonly accountType = signal<string | null>(null);
    readonly category = signal<string | null>(null);
    readonly type = signal<LedgerEntryType | null>(null);

    // local search (client-side)
    readonly q = signal('');

    // paging (client-side)
    readonly page = signal(1);
    readonly pageSize = signal(10);

    // raw data
    readonly entries = signal<LedgerEntryDto[]>([]);

    // mapped rows
    readonly rowsAll = computed<TransactionRow[]>(() => mapLedgerEntriesToRows(this.entries()));

    // filtered
    readonly filteredRows = computed(() => {
        const needle = this.q().trim().toLowerCase();
        const list = this.rowsAll();
        if (!needle) return list;

        return list.filter(r => {
            const hay = [
                r.note,
                r.subtitle,
                r.category,
                r.paymentMethod,
                r.currency,
                r.date,
                String(r.amount),
            ]
                .filter(Boolean)
                .join(' ')
                .toLowerCase();

            return hay.includes(needle);
        });
    });

    // pagination derived
    readonly total = computed(() => this.filteredRows().length);
    readonly totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize())));

    readonly items = computed(() => {
        const start = (this.page() - 1) * this.pageSize();
        return this.filteredRows().slice(start, start + this.pageSize());
    });

    readonly showFrom = computed(() => {
        const t = this.total();
        if (t === 0) return 0;
        return (this.page() - 1) * this.pageSize() + 1;
    });

    readonly showTo = computed(() => {
        const t = this.total();
        if (t === 0) return 0;
        const end = this.page() * this.pageSize();
        return end > t ? t : end;
    });

    constructor() {
        effect(() => {
            const householdId = this.selectedHouseholdId();

            const from = this.from();
            const to = this.to();
            const limit = this.limit();
            const accountType = this.accountType();
            const category = this.category();
            const type = this.type();

            if (!householdId) {
                this.entries.set([]);
                return;
            }

            this.fetchEntries(householdId, { from, to, limit, accountType, category, type });
        });
    }

    // actions
    setSearch(v: string) {
        this.q.set(v);
        this.page.set(1);
    }

    setCategory(v: string | null) {
        this.category.set(v);
        this.page.set(1);
    }

    setType(v: LedgerEntryType | null) {
        this.type.set(v);
        this.page.set(1);
    }

    next() {
        this.goTo(this.page() + 1);
    }

    prev() {
        this.goTo(this.page() - 1);
    }

    goTo(p: number) {
        const clamped = Math.min(Math.max(1, p), this.totalPages());
        this.page.set(clamped);
    }

    // formatting can live here too if you prefer
    formatMoney(amount: number, currency: string) {
        try {
            return new Intl.NumberFormat(undefined, { style: 'currency', currency }).format(amount);
        } catch {
            return `${amount.toFixed(2)} ${currency}`;
        }
    }

    refresh() {
        const householdId = this.selectedHouseholdId();
        if (!householdId) return;

        this.fetchEntries(householdId, {
            from: this.from(),
            to: this.to(),
            limit: this.limit(),
            accountType: this.accountType(),
            category: this.category(),
            type: this.type(),
        });
    }

    delete(entryId: string) {
        const householdId = this.selectedHouseholdId();
        if (!householdId) return;

        this.loading.set(true);
        this.error.set(null);

        this.api.deleteEntry(householdId, entryId)
            .pipe(takeUntilDestroyed(this.destroyRef))
            .subscribe({
                next: () => this.refresh(),
                error: (e: any) => {
                    this.loading.set(false);
                    this.error.set(e?.message ?? 'Failed to delete transaction');
                },
            });
    }

    update(entryId: string, dto: {
        type?: LedgerEntryType;
        amount?: number | string;
        category?: string | null;
        note?: string | null;
        occursAt?: string | Date;
        accountType?: unknown;
    }) {
        const householdId = this.selectedHouseholdId();
        if (!householdId) return;

        this.loading.set(true);
        this.error.set(null);

        this.api
            .updateEntry(householdId, entryId, dto)
            .pipe(takeUntilDestroyed(this.destroyRef))
            .subscribe({
                next: () => this.refresh(),
                error: (e: any) => {
                    this.loading.set(false);
                    this.error.set(e?.message ?? 'Failed to update transaction');
                },
            });
    }

    private fetchEntries(
        householdId: string,
        opts: {
            from: string | null;
            to: string | null;
            limit: number;
            accountType: string | null;
            category: string | null;
            type: LedgerEntryType | null;
        }
    ) {
        this.loading.set(true);
        this.error.set(null);

        this.api
            .listEntries(householdId, {
                from: opts.from ?? undefined,
                to: opts.to ?? undefined,
                limit: opts.limit ?? undefined,
                accountType: opts.accountType ?? undefined,
                category: opts.category ?? undefined,
                type: (opts.type ?? undefined) as any,
            })
            .pipe(takeUntilDestroyed(this.destroyRef))
            .subscribe({
                next: (rows) => {
                    this.entries.set(rows ?? []);
                    this.loading.set(false);
                    this.page.set(1);
                },
                error: (e: any) => {
                    this.loading.set(false);
                    this.error.set(e?.message ?? 'Failed to load transactions');
                },
            });
    }
}
