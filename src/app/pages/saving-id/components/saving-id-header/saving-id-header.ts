import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-saving-id-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './saving-id-header.html',
})
export class SavingIdHeader {
  @Input() goalName = '';
  @Input() busy = false;
  @Output() refresh = new EventEmitter<void>();
}
