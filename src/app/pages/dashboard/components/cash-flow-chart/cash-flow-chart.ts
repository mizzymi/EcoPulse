import { NgFor } from '@angular/common';
import { Component, inject, Input } from '@angular/core';
import { Router } from '@angular/router';

export interface CashFlowSeries {
  name: string;
  values: number[];
  /** stroke color */
  stroke: string;
  /** fill color for area */
  fill: string;
}

@Component({
  selector: 'app-cash-flow-chart',
  imports: [NgFor],
  templateUrl: './cash-flow-chart.html',
})
export class CashFlowChart {
  private readonly router = inject(Router);

  @Input({ required: true }) labels!: string[];
  @Input({ required: true }) series!: CashFlowSeries[];

  @Input() height = 280;
  @Input() width = 760;
  @Input() yTicks = 5;

  /** UI toggle (Income/Expense) - optional */
  @Input() showHeaderToggle = true;
  activeIndex = 0;
  
  goChart(){
    this.router.navigate(['/chart']);
  }

  setActive(i: number) {
    this.activeIndex = i;
  }

  get activeSeries(): CashFlowSeries | null {
    if (!this.series?.length) return null;
    return this.series[this.activeIndex] ?? this.series[0];
  }

  private get allValues(): number[] {
    const out: number[] = [];
    for (const s of this.series ?? []) out.push(...(s.values ?? []));
    return out;
  }

  get maxY(): number {
    const vals = this.allValues;
    const m = vals.length ? Math.max(...vals) : 0;
    // round up to a nicer step
    const step = m === 0 ? 1 : Math.pow(10, Math.floor(Math.log10(m)));
    return Math.ceil(m / step) * step;
  }

  get minY(): number {
    const vals = this.allValues;
    const m = vals.length ? Math.min(...vals) : 0;
    return Math.min(0, m);
  }

  get yTickValues(): number[] {
    const min = this.minY;
    const max = this.maxY;
    const ticks = Math.max(2, this.yTicks);
    const step = (max - min) / (ticks - 1);
    return Array.from({ length: ticks }, (_, i) => min + step * i);
  }

  /** Chart paddings */
  private readonly padL = 52;
  private readonly padR = 20;
  private readonly padT = 18;
  private readonly padB = 34;

  private xFor(i: number): number {
    const n = Math.max(2, this.labels?.length ?? 2);
    const innerW = this.width - this.padL - this.padR;
    return this.padL + (innerW * i) / (n - 1);
  }

  private yFor(v: number): number {
    const min = this.minY;
    const max = this.maxY;
    const innerH = this.height - this.padT - this.padB;
    if (max === min) return this.padT + innerH / 2;
    const t = (v - min) / (max - min);
    return this.padT + innerH * (1 - t);
  }

  linePath(values: number[]): string {
    if (!values?.length) return '';
    return values
      .map((v, i) => `${i === 0 ? 'M' : 'L'} ${this.xFor(i)} ${this.yFor(v)}`)
      .join(' ');
  }

  areaPath(values: number[]): string {
    if (!values?.length) return '';
    const baseY = this.yFor(this.minY);
    const firstX = this.xFor(0);
    const lastX = this.xFor(values.length - 1);

    const line = this.linePath(values);
    return `${line} L ${lastX} ${baseY} L ${firstX} ${baseY} Z`;
  }

  formatMoneyTick(v: number): string {
    // Keep it simple like "$2000"
    const rounded = Math.round(v);
    return `$${rounded}`;
  }
}
