import { Component, inject } from '@angular/core';
import { CommonModule, NgIf, NgClass } from '@angular/common';
import { LucideAngularModule, TriangleAlert, X } from 'lucide-angular';
import { ConfirmDialogService } from '../../services';

export type ConfirmDialogData = {
  title?: string;
  message?: string;
  cancelText?: string;
  confirmText?: string;
  tone?: 'danger' | 'neutral';
};

@Component({
  selector: 'app-confirm-dialog',
  imports: [CommonModule, NgIf, NgClass, LucideAngularModule],
  templateUrl: './confirm-dialog.html',
  styles: ``,
})
export class ConfirmDialog {
  svc = inject(ConfirmDialogService);
  vm = this.svc.state;

  alert = TriangleAlert;
  x = X;
}
