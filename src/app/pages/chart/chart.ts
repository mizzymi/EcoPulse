import { CommonModule } from '@angular/common';
import { Component, computed, effect, inject, signal } from '@angular/core';
import { Container, HouseHoldSelector, Lang, LanguageService, SelectedHouseholdService, LangSwitcher } from '../../shared';
import { ChartsVm, Breakdown, ChartsRange } from './chart.vm';
import { ChartsHeader } from './components/charts-header/charts-header';
import { CategoryDistributionCard } from './components/category-distribution-card/category-distribution-card';
import { MonthlyTrendCard } from './components/monthly-trend-card/monthly-trend-card';

export type BreakdownKey = 'all' | 'cash' | 'card' | 'bank';
export type PeriodKey = 'thisMonth' | 'threeMonths' | 'custom';
export type AccountKey = 'all' | 'myWallet'; // keep if later you filter by accountId

@Component({
  selector: 'app-chart',
  standalone: true,
  imports: [CommonModule, Container, ChartsHeader, CategoryDistributionCard, MonthlyTrendCard, HouseHoldSelector, LangSwitcher],
  templateUrl: './chart.html',
  providers: [ChartsVm],
})
export class Chart {
  readonly vm = inject(ChartsVm);

  private readonly langService = inject(LanguageService);
  readonly lang = computed<Lang>(() => this.langService.lang());

  // ✅ your existing source of truth
  readonly household = inject(SelectedHouseholdService);
  readonly selectedHouseholdId = this.household.selectedHouseholdId;

  // If your service has selectedHousehold() with currency, use it.
  // If not, keep EUR as fallback.
  readonly householdCurrency = computed(() => {
    const h = (this.household as any).selectedHousehold?.();
    return h?.currency ?? 'EUR';
  });

  // UI state
  readonly breakdown = signal<'all' | 'cash' | 'card' | 'bank'>('all');
  readonly period = signal<'thisMonth' | 'threeMonths' | 'custom'>('thisMonth');

  // optional custom range
  readonly from = signal<string | null>(null);
  readonly to = signal<string | null>(null);

  // helper for cards
  readonly formatMoney = (value: number) => this.vm.formatMoney(value, this.lang());

  // ✅ Auto refresh whenever household or filters change
  private readonly _autoRefresh = effect(() => {
    const householdId = this.selectedHouseholdId(); // <-- signal read
    if (!householdId) return;

    const range: ChartsRange =
      this.period() === 'thisMonth' ? 'THIS_MONTH'
        : this.period() === 'threeMonths' ? 'THREE_MONTHS'
          : 'CUSTOM';

    const apiBreakdown: Breakdown =
      this.breakdown() === 'all' ? 'ALL'
        : this.breakdown() === 'cash' ? 'CASH'
          : this.breakdown() === 'card' ? 'CARD'
            : 'BANK';

    this.vm.refresh({
      householdId,
      currency: this.householdCurrency(),
      range,
      breakdown: apiBreakdown,
      from: this.from() ?? undefined,
      to: this.to() ?? undefined,
    });
  });

  // UI events
  setBreakdown(key: 'all' | 'cash' | 'card' | 'bank') {
    this.breakdown.set(key);
  }

  setPeriod(key: 'thisMonth' | 'threeMonths' | 'custom') {
    this.period.set(key);
  }

  onRangeChange(range: { from: string | null; to: string | null }) {
    this.from.set(range.from);
    this.to.set(range.to);
  }

  readonly breakdownOptions = computed(() => {
    const lang = this.lang();
    return [
      { key: 'all' as const, label: translateBreakdown('all', lang) },
      { key: 'cash' as const, label: translateBreakdown('cash', lang) },
      { key: 'card' as const, label: translateBreakdown('card', lang) },
      { key: 'bank' as const, label: translateBreakdown('bank', lang) },
    ];
  });

  readonly periodOptions = computed(() => {
    const lang = this.lang();
    return [
      { key: 'thisMonth' as const, label: translatePeriod('thisMonth', lang) },
      { key: 'threeMonths' as const, label: translatePeriod('threeMonths', lang) },
      { key: 'custom' as const, label: translatePeriod('custom', lang) },
    ];
  });
}

function translateBreakdown(key: BreakdownKey, lang: Lang): string {
  const en = { all: 'All', cash: 'Cash', card: 'Card', bank: 'Bank' } as const;
  const es = { all: 'Todo', cash: 'Efectivo', card: 'Tarjeta', bank: 'Banco' } as const;
  const ca = { all: 'Tot', cash: 'Efectiu', card: 'Targeta', bank: 'Banc' } as const;
  const gl = { all: 'Todo', cash: 'Efectivo', card: 'Tarxeta', bank: 'Banco' } as const;

  if (lang === 'es') return es[key];
  if (lang === 'ca') return ca[key];
  if (lang === 'gl') return gl[key];
  return en[key];
}

function translatePeriod(key: PeriodKey, lang: Lang): string {
  const en = { thisMonth: 'This Month', threeMonths: '3 Months', custom: 'Custom' } as const;
  const es = { thisMonth: 'Este mes', threeMonths: '3 meses', custom: 'Personalizado' } as const;
  const ca = { thisMonth: 'Aquest mes', threeMonths: '3 mesos', custom: 'Personalitzat' } as const;
  const gl = { thisMonth: 'Este mes', threeMonths: '3 meses', custom: 'Personalizado' } as const;

  if (lang === 'es') return es[key];
  if (lang === 'ca') return ca[key];
  if (lang === 'gl') return gl[key];
  return en[key];
}
