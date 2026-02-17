import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-history-pagination',
  standalone: true,
  templateUrl: './history-pagination.html',
})
export class HistoryPagination {
  @Input() page = 1;
  @Input() totalPages = 1;

  @Input() showFrom = 0;
  @Input() showTo = 0;
  @Input() total = 0;

  @Output() prev = new EventEmitter<void>();
  @Output() next = new EventEmitter<void>();
}
