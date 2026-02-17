import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SavingsTxnDto } from '../../../../shared';

@Component({
  selector: 'app-saving-id-txns-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './saving-id-txns-list.html',
})
export class SavingIdTxnsList {
  @Input() loading = false;
  @Input() rows: SavingsTxnDto[] = [];
  @Input() busy = false;

  @Output() deleteTxn = new EventEmitter<SavingsTxnDto>();

  @Input() trackBy: ((index: number, row: SavingsTxnDto) => any) | null = null;
  track = (i: number, r: SavingsTxnDto) => (this.trackBy ? this.trackBy(i, r) : r.id);

  onDelete(ev: MouseEvent, t: SavingsTxnDto) {
    ev.stopPropagation();
    this.deleteTxn.emit(t);
  }
}
