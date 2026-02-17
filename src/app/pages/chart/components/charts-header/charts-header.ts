import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { AccountKey, BreakdownKey, PeriodKey } from '../../chart';

type Option<T extends string> = { key: T; label: string };

export type DateRange = { from: string | null; to: string | null };

@Component({
  selector: 'app-charts-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './charts-header.html',
})
export class ChartsHeader {
  @Input({ required: true }) breakdown!: BreakdownKey;
  @Input({ required: true }) period!: PeriodKey;

  // If you still use account selector, keep it. If not, remove.
  @Input() account?: AccountKey;
  @Input() accountOptions?: Option<AccountKey>[];

  @Input({ required: true }) breakdownOptions!: Option<BreakdownKey>[];
  @Input({ required: true }) periodOptions!: Option<PeriodKey>[];

  @Input({ required: true }) totalSpent!: number;
  @Input({ required: true }) formatMoney!: (value: number, currency?: string) => string;

  // ✅ Custom range inputs controlled by parent (page)
  @Input() from: string | null = null; // YYYY-MM-DD
  @Input() to: string | null = null;   // YYYY-MM-DD

  @Output() breakdownChange = new EventEmitter<BreakdownKey>();
  @Output() periodChange = new EventEmitter<PeriodKey>();

  // Optional account
  @Output() accountChange = new EventEmitter<AccountKey>();

  // ✅ Date range change
  @Output() rangeChange = new EventEmitter<DateRange>();

  // UI state for the picker
  pickerOpen = false;

  setBreakdown(key: BreakdownKey) {
    this.breakdownChange.emit(key);
  }

  setPeriod(key: PeriodKey) {
    this.periodChange.emit(key);

    // Open picker when custom is selected, close otherwise
    this.pickerOpen = key === 'custom';
  }

  setAccount(key: AccountKey) {
    this.accountChange.emit(key);
  }

  togglePicker() {
    this.pickerOpen = !this.pickerOpen;
  }

  onFromChange(value: string) {
    const from = value?.trim() ? value : null;
    this.rangeChange.emit({ from, to: this.to });
  }

  onToChange(value: string) {
    const to = value?.trim() ? value : null;
    this.rangeChange.emit({ from: this.from, to });
  }

  applyRange() {
    this.pickerOpen = false;
  }

  clearRange() {
    this.rangeChange.emit({ from: null, to: null });
  }
}
