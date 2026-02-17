import { CommonModule } from '@angular/common';
import { Component, Input, computed, signal } from '@angular/core';

type DonutItem = { amount: number; color: string };

@Component({
  selector: 'app-donut-chart',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './donut-chart.html',
})
export class DonutChart {
  @Input({ required: true }) items!: DonutItem[];

  @Input() topLabel = '—';
  @Input() topPercent = '0%';

  private readonly _items = signal<DonutItem[]>([]);

  ngOnChanges() {
    this._items.set(this.items ?? []);
  }

  readonly donutStyle = computed(() => {
    const rows = this._items();
    const total = rows.reduce((acc, r) => acc + (r.amount ?? 0), 0) || 1;

    let start = 0;
    const stops: string[] = [];

    for (const r of rows) {
      const pct = ((r.amount ?? 0) / total) * 100;
      const end = start + pct;
      stops.push(`${r.color} ${start.toFixed(2)}% ${end.toFixed(2)}%`);
      start = end;
    }

    return { background: `conic-gradient(${stops.join(', ')})` } as const;
  });
}
