import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { LedgerEntryType } from '../../../../../shared';

@Component({
  selector: 'app-filters-bar',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './filters-bar.html',
})
export class FiltersBar {
  readonly facade = inject(RecurrentFacade);

  readonly types: Array<{ value: LedgerEntryType | ''; label: string; i18nId: string }> = [
    { value: '', label: 'All', i18nId: '@@recurrent.filters.type.all' },
    { value: 'INCOME', label: 'Income', i18nId: '@@recurrent.filters.type.income' },
    { value: 'EXPENSE', label: 'Expense', i18nId: '@@recurrent.filters.type.expense' },
  ];

  onMonth(v: string) {
    this.facade.month.set(v);
  }
  onType(v: LedgerEntryType | '') {
    this.facade.type.set(v);
  }
  onCategory(v: string) {
    this.facade.category.set(v);
  }
  onAccountType(v: string) {
    this.facade.accountType.set(v);
  }

  clear(): void {
    this.facade.type.set('');
    this.facade.category.set('');
    this.facade.accountType.set('');
  }
}
