import { Component, EventEmitter, Input, Output } from '@angular/core';
import { NgIf } from '@angular/common';

@Component({
  selector: 'app-hh-create-form',
  standalone: true,
  imports: [NgIf],
  templateUrl: './hh-create-form.html',
})
export class HhCreateForm {
  @Input({ required: true }) busy!: boolean;
  @Input() error: string | null = null;

  @Input({ required: true }) name!: string;
  @Input({ required: true }) currency!: string;

  @Output() nameChange = new EventEmitter<string>();
  @Output() currencyChange = new EventEmitter<string>();

  @Output() cancel = new EventEmitter<void>();
  @Output() create = new EventEmitter<void>();
}
