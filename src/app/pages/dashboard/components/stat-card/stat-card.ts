import { Component, Input } from '@angular/core';
import { NgClass, NgIf } from '@angular/common';
import { LucideAngularModule } from 'lucide-angular';

export type StatCardTone = 'neutral' | 'positive' | 'negative' | 'dark';

@Component({
  selector: 'app-stat-card',
  imports: [NgClass, NgIf, LucideAngularModule],
  templateUrl: './stat-card.html',
})

export class StatCard {
  @Input({ required: true }) title!: string;
  @Input({ required: true }) value!: string;

  /** Small pill on the top-right like "Current" */
  @Input() badge?: string;

  /** Small change indicator like "+12%" / "-4%" */
  @Input() delta?: string;
  @Input() deltaTone: 'up' | 'down' | 'muted' = 'muted';

  /** Left icon: use an emoji or short text (or replace with your icon component) */
  @Input() icon: any | null = null;

  /** Card tone */
  @Input() tone: StatCardTone = 'neutral';

  toneClasses(): string {
    switch (this.tone) {
      case 'positive':
        return 'bg-white border border-slate-100';
      case 'negative':
        return 'bg-white border border-slate-100';
      case 'dark':
        return 'bg-teal-700 text-white border border-teal-650';
      default:
        return 'bg-white border border-slate-100';
    }
  }

  iconWrapClasses(): string {
    switch (this.tone) {
      case 'positive':
        return 'bg-emerald-50 text-emerald-600';
      case 'negative':
        return 'bg-rose-50 text-rose-600';
      case 'dark':
        return 'bg-white/10 text-white';
      default:
        return 'bg-slate-100 text-slate-700';
    }
  }

  deltaClasses(): string {
    if (this.deltaTone === 'up') return 'bg-emerald-50 text-emerald-700';
    if (this.deltaTone === 'down') return 'bg-rose-50 text-rose-700';
    return 'bg-slate-100 text-slate-700';
  }
}
