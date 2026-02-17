import { Injectable, inject } from '@angular/core';
import { Observable, combineLatest, map } from 'rxjs';
import { ApiService, LedgerEntryDto, MonthlySummaryDto, PlannedItemDto, RecurringDefDto, SavingsGoalDto } from '../../../../shared';
import { UpcomingBill } from '../upcoming-bills/upcoming-bills';


export type DashboardCardsVm = {
    totalBalance: number;
    income: number;
    expenses: number;
    savings: number;
};

export type DashboardChartVm = {
    labels: string[];
    incomeByWeek: number[];
    expenseByWeek: number[];
};

export type FinancialOverviewVm = {
    month: string;
    cards: {
        totalBalance: number;
        income: number;
        expenses: number;
        savings: number;
    };
    chart: {
        labels: string[];
        incomeByWeek: number[];
        expenseByWeek: number[];
    };
    upcoming: UpcomingBill[];
};

@Injectable({ providedIn: 'root' })
export class FinancialOverviewDataService {
    private api = inject(ApiService);

    /**
     * Main VM builder for the page.
     * - Gets summary => cards
     * - Gets entries in month => chart (grouped by week)
     * - Gets planned + recurring (projected) => upcoming bills
     */
    getVm(householdId: string, month: string): Observable<FinancialOverviewVm> {
        const { fromIso, toIso } = monthUtcRange(month);

        const summary$ = this.api.monthlySummary(householdId, month);
        const entries$ = this.api.listEntries(householdId, { from: fromIso, to: toIso, limit: 500 });
        const planned$ = this.api.listPlanned(householdId, { month });
        const recurring$ = this.api.listRecurring(householdId, { month });

        // ✅ NEW: savings goals includes computed "saved"
        const savingsGoals$ = this.api.listSavingsGoals(householdId);

        return combineLatest([summary$, entries$, planned$, recurring$, savingsGoals$]).pipe(
            map(([summary, entries, planned, recurring, goals]) => {
                const cards = mapCards(summary, goals);
                const chart = mapChart(entries, month);
                const upcoming = mapUpcoming(planned, recurring);
                return { month, cards, chart, upcoming };
            }),
        );
    }
}

/* =========================================================
   Mapping helpers
   ========================================================= */

function mapCards(s: MonthlySummaryDto, goals: SavingsGoalDto[]): DashboardCardsVm {
    const savings = round2(
        (goals ?? []).reduce((acc, g: any) => acc + Number(g.saved ?? 0), 0),
    );

    return {
        totalBalance: s.closingBalance,
        income: s.income,
        expenses: s.expense,
        savings,
    };
}


function mapChart(entries: LedgerEntryDto[], month: string): DashboardChartVm {
    // We will always return 4 labels like your screenshot.
    const labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];

    const buckets = [
        { income: 0, expense: 0 },
        { income: 0, expense: 0 },
        { income: 0, expense: 0 },
        { income: 0, expense: 0 },
    ];

    const { y, m } = parseMonth(month);
    const daysIn = daysInMonthUtc(y, m);

    for (const e of entries) {
        const d = new Date(e.occursAt);
        const day = d.getUTCDate(); // 1..31

        const weekIdx = weekIndexFromDay(day, daysIn); // 0..3
        if (e.type === 'INCOME') buckets[weekIdx].income += Number(e.amount || 0);
        else buckets[weekIdx].expense += Number(e.amount || 0);
    }

    return {
        labels,
        incomeByWeek: buckets.map((b) => round2(b.income)),
        expenseByWeek: buckets.map((b) => round2(b.expense)),
    };
}

function mapUpcoming(planned: PlannedItemDto[], recurring: RecurringDefDto[]): UpcomingBill[] {
    const plannedItems: UpcomingBill[] = planned.map((p) => ({
        title: p.concept,
        subtitle: formatShortDate(new Date(p.dueDate)),
        amount: p.type === 'EXPENSE' ? -Number(p.amount) : Number(p.amount),
        tag: 'Planned',
        iconText: p.type === 'EXPENSE' ? '📌' : '💰',
        occursAt: new Date(p.dueDate),
    }));

    const recurringItems: UpcomingBill[] = recurring
        .filter((r) => !!r.occursAt)
        .map((r) => ({
            title: r.concept,
            subtitle: formatShortDate(new Date(r.occursAt!)),
            amount: r.type === 'EXPENSE' ? -Number(r.amount) : Number(r.amount),
            tag: 'Recurring',
            iconText: r.type === 'EXPENSE' ? '🔁' : '🔁',
            occursAt: new Date(r.occursAt!),
        }));

    return [...plannedItems, ...recurringItems]
        .sort((a, b) => a.occursAt.getTime() - b.occursAt.getTime())
        .slice(0, 10);
}

/* =========================================================
   Date helpers
   ========================================================= */

function parseMonth(month: string): { y: number; m: number } {
    // month: YYYY-MM
    const [yStr, mStr] = month.split('-');
    return { y: Number(yStr), m: Number(mStr) };
}

function monthUtcRange(month: string): { fromIso: string; toIso: string } {
    const { y, m } = parseMonth(month);
    const from = new Date(Date.UTC(y, m - 1, 1, 0, 0, 0, 0));
    const to = new Date(Date.UTC(y, m, 0, 23, 59, 59, 999));
    return { fromIso: from.toISOString(), toIso: to.toISOString() };
}

function daysInMonthUtc(y: number, m: number): number {
    // m is 1..12
    return new Date(Date.UTC(y, m, 0)).getUTCDate();
}

function weekIndexFromDay(day: number, dim: number): number {
    // Split the month into 4 roughly equal ranges
    const q = dim / 4;
    if (day <= Math.ceil(q * 1)) return 0;
    if (day <= Math.ceil(q * 2)) return 1;
    if (day <= Math.ceil(q * 3)) return 2;
    return 3;
}

function formatShortDate(d: Date): string {
    // Example: "Feb 20, 2026"
    return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: '2-digit' });
}

function round2(n: number): number {
    return Math.round(n * 100) / 100;
}
