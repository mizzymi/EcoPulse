import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-hh-selector-trigger',
  standalone: true,
  imports: [],
  templateUrl: './hh-selector-trigger.html',
})
export class HhSelectorTrigger {
  @Input({ required: true }) open!: boolean;
  @Input({ required: true }) loading!: boolean;
  @Input() error: string | null = null;

  @Input({ required: true }) initials!: string;
  @Input({ required: true }) name!: string;
  @Input({ required: true }) roleLabel!: string;

  @Output() toggle = new EventEmitter<void>();
  @Output() refresh = new EventEmitter<void>();
}
