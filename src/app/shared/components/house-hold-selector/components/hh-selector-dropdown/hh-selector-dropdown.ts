import { Component, EventEmitter, Input, Output } from '@angular/core';
import { NgIf } from '@angular/common';

import { HouseholdListItemDto } from '../../../../services';
import { HhHouseholdList } from '../hh-household-list/hh-household-list';
import { HhCreateForm } from '../hh-create-form/hh-create-form';

@Component({
  selector: 'app-hh-selector-dropdown',
  standalone: true,
  imports: [NgIf, HhHouseholdList, HhCreateForm],
  templateUrl: './hh-selector-dropdown.html',
})
export class HhSelectorDropdown {
  @Input({ required: true }) households!: HouseholdListItemDto[];
  @Input({ required: true }) selectedId!: string | null;

  @Input({ required: true }) creating!: boolean;
  @Input({ required: true }) creatingBusy!: boolean;
  @Input() createError: string | null = null;

  @Input({ required: true }) newName!: string;
  @Input({ required: true }) newCurrency!: string;

  @Output() selectHousehold = new EventEmitter<HouseholdListItemDto>();

  @Output() startCreate = new EventEmitter<void>();
  @Output() cancelCreate = new EventEmitter<void>();
  @Output() createHousehold = new EventEmitter<void>();

  @Output() nameChange = new EventEmitter<string>();
  @Output() currencyChange = new EventEmitter<string>();
}
