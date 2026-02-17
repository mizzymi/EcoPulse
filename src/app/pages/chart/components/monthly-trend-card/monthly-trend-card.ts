import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

export type MonthRow = {
  key: string;
  income: number;
  expense: number;
};

@Component({
  selector: 'app-monthly-trend-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './monthly-trend-card.html',
})
export class MonthlyTrendCard {
  @Input({ required: true }) months!: MonthRow[];

  @Input({ required: true }) formatMoney!: (value: number, currency?: string) => string;

  maxValue(): number {
    const rows = this.months ?? [];
    let max = 1;
    for (const r of rows) max = Math.max(max, r.income, r.expense);
    return max;
  }

  heightPct(value: number): string {
    const max = this.maxValue();
    return `${Math.round((value / max) * 100)}%`;
  }

  trackByKey(_: number, row: MonthRow) {
    return row.key;
  }
}
