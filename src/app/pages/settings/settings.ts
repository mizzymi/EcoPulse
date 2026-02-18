import { Component, inject } from '@angular/core';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

import { Container, HouseHoldSelector, LangSwitcher } from '../../shared';
import { SettingsShell } from './components';
import { SettingsDataService } from './services';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [Container, HouseHoldSelector, LangSwitcher, SettingsShell],
  templateUrl: './settings.html',
  providers: [SettingsDataService],
})
export class Settings {
  private bp = inject(BreakpointObserver);
  readonly data = inject(SettingsDataService);

  isSmall = toSignal(
    this.bp.observe('(max-width: 639px)').pipe(map(r => r.matches)),
    { initialValue: false }
  );

  ngOnInit() {
    this.data.init();
  }
}
