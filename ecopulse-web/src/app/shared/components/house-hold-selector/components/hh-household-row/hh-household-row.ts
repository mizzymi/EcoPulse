import { Component, EventEmitter, Input, Output } from '@angular/core';
import { HouseholdListItemDto } from '../../../../services';
import { NgIf } from '@angular/common';

@Component({
  selector: 'app-hh-household-row',
  imports: [NgIf],
  standalone: true,
  templateUrl: './hh-household-row.html',
})
export class HhHouseholdRow {
  @Input({ required: true }) household!: HouseholdListItemDto;
  @Input() selected = false;

  @Output() select = new EventEmitter<void>();

  get roleLabel(): string {
    switch (this.household.role) {
      case 'OWNER':
        return $localize`:@@household.role.owner:Owner`;
      case 'ADMIN':
        return $localize`:@@household.role.admin:Admin`;
      default:
        return $localize`:@@household.role.member:Member`;
    }
  }
}
