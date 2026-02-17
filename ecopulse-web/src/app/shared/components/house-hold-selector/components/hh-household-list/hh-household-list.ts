import { Component, EventEmitter, Input, Output } from '@angular/core';
import { NgFor } from '@angular/common';

import { HouseholdListItemDto } from '../../../../services';
import { HhHouseholdRow } from '../hh-household-row/hh-household-row';

@Component({
  selector: 'app-hh-household-list',
  standalone: true,
  imports: [NgFor, HhHouseholdRow],
  templateUrl: './hh-household-list.html', 
})
export class HhHouseholdList {
  @Input({ required: true }) households!: HouseholdListItemDto[];
  @Input({ required: true }) selectedId!: string | null;

  @Output() selectHousehold = new EventEmitter<HouseholdListItemDto>();
  @Output() startCreate = new EventEmitter<void>();
}
