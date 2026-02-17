import { Component, EventEmitter, Input, Output } from '@angular/core';
import { LedgerEntryType } from '../../../../shared';

@Component({
  selector: 'app-history-filters',
  standalone: true,
  templateUrl: './history-filters.html',
})
export class HistoryFilters {
  @Input() q = '';

  @Output() search = new EventEmitter<string>();
  @Output() category = new EventEmitter<string | null>();
  @Output() type = new EventEmitter<LedgerEntryType | null>();

  onInput(v: string) {
    this.search.emit(v);
  }

  clearCategory() {
    this.category.emit(null);
  }

  clearType() {
    this.type.emit(null);
  }
}
