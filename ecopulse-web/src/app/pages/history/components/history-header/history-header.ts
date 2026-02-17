import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-history-header',
  standalone: true,
  templateUrl: './history-header.html',
})
export class HistoryHeader {
  @Input() isSmall = false;
  @Output() addNew = new EventEmitter<void>();
}
