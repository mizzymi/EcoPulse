import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { DonutChart } from '../donut-chart/donut-chart';

type CategoryUi = {
  label: string;
  amount: number;
  color: string;
};

@Component({
  selector: 'app-category-distribution-card',
  standalone: true,
  imports: [CommonModule, DonutChart],
  templateUrl: './category-distribution-card.html',
})
export class CategoryDistributionCard {
  @Input({ required: true }) items!: CategoryUi[];
  @Input({ required: true }) total!: number;
  @Input({ required: true }) formatMoney!: (value: number, currency?: string) => string;

  percentOfTotal(value: number): string {
    const total = this.total || 1;
    return `${Math.round((value / total) * 100)}%`;
  }

  get top() {
    return [...(this.items ?? [])].sort((a, b) => b.amount - a.amount)[0] ?? null;
  }

  trackByLabel(_: number, item: CategoryUi) {
    return item.label;
  }
}
