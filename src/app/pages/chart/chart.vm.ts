import { Injectable, computed, inject, signal } from '@angular/core';
import { catchError, finalize, map, of, tap } from 'rxjs';
import { ApiService, Lang, LedgerEntryDto, MoneyType, translateCategory } from '../../shared';

export type UiCategoryRow = {
    category: string | null;
    label: string;
    amount: number;
    color: string;
};

export type UiMonthRow = {
    key: string; // "Jan", "Feb"...
    month: string; // "YYYY-MM"
    income: number;
    expense: number;
};

export type ChartsRange = 'THIS_MONTH' | 'THREE_MONTHS' | 'CUSTOM';
export type Breakdown = 'ALL' | 'CASH' | 'CARD' | 'BANK';

export type ChartsQuery = {
    householdId: string;
    currency: string;         // household currency (EUR, USD...)
    range: ChartsRange;
    breakdown: Breakdown;
    from?: string;            // YYYY-MM-DD (required for CUSTOM)
    to?: string;              // YYYY-MM-DD (required for CUSTOM)
};

@Injectable()
export class ChartsVm {
    private readonly api = inject(ApiService);

    // Base state
    readonly loading = signal(false);
    readonly error = signal<string | null>(null);

    // Raw fetched entries
    readonly entries = signal<LedgerEntryDto[]>([]);

    // Currency for formatting
    readonly currency = signal('EUR');

    // Derived aggregates
    readonly totalSpent = computed(() => {
        // total spent = sum of EXPENSE amounts (absolute)
        return this.entries()
            .filter((e) => e.type === 'EXPENSE')
            .reduce((acc, e) => acc + Math.abs(Number(e.amount ?? 0)), 0);
    });


    /** Build translated category rows (dynamic labels in TS, like your History mapping). */
    categoriesUi(lang: Lang): UiCategoryRow[] {
        const rows = this.entries();

        // group by category (null included as '—')
        const mapByCategory = new Map<string, number>();

        for (const e of rows) {
            if (e.type !== 'EXPENSE') continue;
            const key = (e.category ?? null) as any;
            const k = key === null ? '__NULL__' : String(key);
            const prev = mapByCategory.get(k) ?? 0;
            mapByCategory.set(k, prev + Math.abs(Number(e.amount ?? 0)));
        }

        // stable palette by category key
        const colorFor = (category: string | null): string => {
            const k = category ?? '__NULL__';
            const palette: Record<string, string> = {
                HOUSING: '#14b8a6',
                FOOD: '#22c55e',
                TRANSPORT: '#f59e0b',
                SUBSCRIPTIONS: '#a855f7',
                HEALTH: '#60a5fa',
                SHOPPING: '#fb7185',
                OTHER: '#94a3b8',
                '__NULL__': '#94a3b8',
            };
            return palette[k] ?? '#94a3b8';
        };

        const out: UiCategoryRow[] = [];
        for (const [k, amount] of mapByCategory.entries()) {
            const category = k === '__NULL__' ? null : k;
            out.push({
                category,
                label: category ? translateCategory(category, lang) : '—',
                amount,
                color: colorFor(category),
            });
        }

        // sort desc
        out.sort((a, b) => b.amount - a.amount);
        return out;
    }

    /** Monthly trend based on entries (income vs expense grouped by YYYY-MM). */
    monthlyUi(lang: Lang): UiMonthRow[] {
        const rows = this.entries();
        const byMonth = new Map<string, { income: number; expense: number }>();

        for (const e of rows) {
            const iso = (e.occursAt ?? e.createdAt ?? new Date().toISOString()).toString();
            const month = iso.slice(0, 7); // "YYYY-MM"
            const cur = byMonth.get(month) ?? { income: 0, expense: 0 };

            const amount = Math.abs(Number(e.amount ?? 0));
            if (e.type === 'INCOME') cur.income += amount;
            if (e.type === 'EXPENSE') cur.expense += amount;

            byMonth.set(month, cur);
        }

        const monthsSorted = [...byMonth.keys()].sort(); // ascending

        return monthsSorted.map((m) => {
            const val = byMonth.get(m)!;
            return {
                month: m,
                key: this.monthLabel(m, lang),
                income: val.income,
                expense: val.expense,
            };
        });
    }

    /** Main entry point: fetch from API + apply filters. */
    refresh(q: ChartsQuery) {
        this.loading.set(true);
        this.error.set(null);
        this.currency.set(q.currency ?? 'EUR');

        const { from, to } = resolveRangeToDates(q.range, q.from, q.to);

        // Translate breakdown to accountType filter for API
        // Your api.listEntries accepts accountType as string; we pass CASH/CARD/BANK or omit for ALL
        const accountType =
            q.breakdown === 'ALL' ? undefined :
                q.breakdown === 'CASH' ? ('CASH' as MoneyType) :
                    q.breakdown === 'CARD' ? ('CARD' as MoneyType) :
                        ('BANK' as MoneyType);

        this.api
            .listEntries(q.householdId, {
                from,
                to,
                accountType: accountType as any,
                // you can also pass type/category here if you want server filtering
            })
            .pipe(
                map((rows) =>
                    (rows ?? []).map((e) => ({
                        ...e,
                        amount: typeof (e as any).amount === 'string' ? Number((e as any).amount) : Number(e.amount ?? 0),
                    })),
                ),
                tap((rows) => this.entries.set(rows)),
                catchError((err) => {
                    this.entries.set([]);
                    this.error.set(err?.message ?? 'Failed to load charts.');
                    return of([]);
                }),
                finalize(() => this.loading.set(false)),
            )
            .subscribe();
    }

    formatMoney(value: number, lang: Lang): string {
        const locale =
            lang === 'es' ? 'es-ES' :
                lang === 'ca' ? 'ca-ES' :
                    lang === 'gl' ? 'gl-ES' :
                        'en-US';

        return new Intl.NumberFormat(locale, {
            style: 'currency',
            currency: this.currency(),
        }).format(value);
    }

    private monthLabel(monthYYYYMM: string, lang: Lang): string {
        // We keep month axis short in English-like abbreviations
        // If you want localized month names, use locale from lang.
        const locale =
            lang === 'es' ? 'es-ES' :
                lang === 'ca' ? 'ca-ES' :
                    lang === 'gl' ? 'gl-ES' :
                        'en-US';

        const [y, m] = monthYYYYMM.split('-').map(Number);
        const d = new Date(y, (m ?? 1) - 1, 1);
        return d.toLocaleString(locale, { month: 'short' });
    }
}

/* =========================================================
   Date range helper
   ========================================================= */

function pad2(n: number) {
    return String(n).padStart(2, '0');
}

function toYMD(d: Date): string {
    return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

/**
 * Resolves range to from/to dates in YYYY-MM-DD.
 * - THIS_MONTH: first day of current month to today
 * - THREE_MONTHS: 3 months ago (start of that month) to today
 * - CUSTOM: uses q.from/q.to (must be provided)
 */
function resolveRangeToDates(range: ChartsRange, from?: string, to?: string): { from: string; to: string } {
    const today = new Date();
    const toYmd = toYMD(today);

    if (range === 'CUSTOM') {
        const safeFrom = from ?? toYmd;
        const safeTo = to ?? safeFrom;
        return { from: safeFrom, to: safeTo };
    }


    if (range === 'THIS_MONTH') {
        const start = new Date(today.getFullYear(), today.getMonth(), 1);
        return { from: toYMD(start), to: toYmd };
    }

    const start = new Date(today.getFullYear(), today.getMonth() - 2, 1);
    return { from: toYMD(start), to: toYmd };
}
