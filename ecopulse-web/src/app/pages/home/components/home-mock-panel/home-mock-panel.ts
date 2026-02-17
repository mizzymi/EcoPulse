import { BreakpointObserver } from '@angular/cdk/layout';
import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

@Component({
  selector: 'app-home-mock-panel',
  standalone: true,
  templateUrl: './home-mock-panel.html',
})
export class HomeMockPanel {

  private bp = inject(BreakpointObserver);

  isSmall = toSignal(
    this.bp.observe('(max-width: 1024px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );
}
