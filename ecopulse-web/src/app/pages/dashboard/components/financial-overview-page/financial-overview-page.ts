import { Component, computed, input, signal, inject } from '@angular/core';
import { AsyncPipe, NgIf } from '@angular/common';

import { StatCard } from '../stat-card/stat-card';
import { CashFlowChart } from '../cash-flow-chart/cash-flow-chart';
import { UpcomingBills } from '../upcoming-bills/upcoming-bills';
import { FinancialOverviewDataService } from './financial-overview-page.data';
import { LucideAngularModule, Wallet, ArrowUpRight, ArrowDownRight, Scale, Calendar, ChevronLeft, ChevronRight } from 'lucide-angular';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

@Component({
  selector: 'app-financial-overview-page',
  standalone: true,
  imports: [NgIf, AsyncPipe, StatCard, CashFlowChart, UpcomingBills, LucideAngularModule],
  templateUrl: './financial-overview-page.html',
})
export class FinancialOverviewPage {
  private data = inject(FinancialOverviewDataService);
  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  householdId = input<string | null>(null);

  // Month state only in TS (YYYY-MM)
  month = signal<string>(toYYYYMMUtc(new Date()));
  monthLabel = computed(() => formatMonthLabel(this.month()));

  // ✅ expose icons for template
  iconCalendar = Calendar;
  iconPrev = ChevronLeft;
  iconNext = ChevronRight;
  iconBalance = Wallet;
  iconIncome = ArrowUpRight;
  iconExpenses = ArrowDownRight;
  iconNet = Scale;
  incomeLabel = $localize`:@@chart.series.income:Income`;
  expenseLabel = $localize`:@@chart.series.expense:Expense`;

  vm$ = computed(() => {
    const householdId = this.householdId();
    if (!householdId) return null;
    return this.data.getVm(householdId, this.month());
  });

  prevMonth() {
    this.month.set(addMonthsYYYYMM(this.month(), -1));
  }

  nextMonth() {
    this.month.set(addMonthsYYYYMM(this.month(), 1));
  }

  formatMoney(n: number): string {
    return n.toLocaleString(undefined, { style: 'currency', currency: 'EUR' });
  }
}

/* ===== Month helpers (UTC safe) ===== */
function isYYYYMM(v: string): boolean {
  return /^\d{4}-\d{2}$/.test(v);
}

function toYYYYMMUtc(d: Date): string {
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

function addMonthsYYYYMM(month: string, delta: number): string {
  if (!isYYYYMM(month)) return month;
  const [yStr, mStr] = month.split('-');
  const d = new Date(Date.UTC(Number(yStr), Number(mStr) - 1, 1));
  d.setUTCMonth(d.getUTCMonth() + delta);
  return toYYYYMMUtc(d);
}

function formatMonthLabel(month: string): string {
  if (!isYYYYMM(month)) return month;
  const [yStr, mStr] = month.split('-');
  const d = new Date(Date.UTC(Number(yStr), Number(mStr) - 1, 1));
  return d.toLocaleDateString(undefined, { month: 'short', year: 'numeric' });
}
