import { Component, Input } from '@angular/core';
import { NgFor, NgIf } from '@angular/common';
import { LucideAngularModule, LucideIconData } from 'lucide-angular';

export interface UpcomingBill {
  title: string;
  subtitle: string;
  amount: number;
  tag?: string;
  icon?: LucideIconData | null;
  occursAt: Date;
}

@Component({
  selector: 'app-upcoming-bills',
  standalone: true,
  imports: [NgFor, NgIf, LucideAngularModule],
  templateUrl: './upcoming-bills.html',
})
export class UpcomingBills {
  @Input({ required: true }) bills!: UpcomingBill[];
  @Input() header = 'Upcoming Bills';
  @Input() actionText = 'See All';

  formatAmount(v: number): string {
    const abs = Math.abs(v);
    const formatted = abs.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    return (v < 0 ? '-' : '+') + '$' + formatted;
  }
}
