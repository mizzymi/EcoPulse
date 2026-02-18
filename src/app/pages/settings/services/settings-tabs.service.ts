import { Injectable, signal } from '@angular/core';

export type SettingsTabKey = 'invite' | 'members';

@Injectable()
export class SettingsTabsService {
    readonly tab = signal<SettingsTabKey>('invite');

    setTab(tab: SettingsTabKey) {
        this.tab.set(tab);
    }
}
