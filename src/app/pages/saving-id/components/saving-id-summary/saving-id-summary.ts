import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-saving-id-summary',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './saving-id-summary.html',
})
export class SavingIdSummary {
  @Input() loading = false;
  @Input() saved = 0;
  @Input() target = 0;
  @Input() progressPct = 0;
  @Input() deadline: string | Date | null = null;

  deadlineLabel(): string | null {
    if (!this.deadline) return null;
    const d = this.deadline instanceof Date ? this.deadline : new Date(this.deadline);
    if (Number.isNaN(d.getTime())) return null;
    return d.toLocaleDateString();
  }
}
