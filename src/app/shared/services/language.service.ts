import { Injectable, signal } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { inject } from '@angular/core';

export type Lang = 'en' | 'es' | 'ca' | 'gl';
export type Locale = 'en-US' | 'es-ES' | 'ca-ES' | 'gl-ES';

@Injectable({ providedIn: 'root' })
export class LanguageService {
    private doc = inject(DOCUMENT);

    readonly lang = signal<Lang>('en');

    constructor() {
        this.syncFromUrl();
    }

    /** Call this on app start (constructor already does it) */
    syncFromUrl() {
        const supported: Locale[] = ['en-US', 'es-ES', 'ca-ES', 'gl-ES'];
        const first = this.doc.location.pathname.split('/').filter(Boolean)[0] as Locale | undefined;

        const locale: Locale = supported.includes(first as Locale) ? (first as Locale) : 'en-US';
        this.lang.set(localeToLang(locale));
    }

    setLang(lang: Lang) {
        this.lang.set(lang);
    }
}

export function localeToLang(locale: Locale): Lang {
    switch (locale) {
        case 'es-ES': return 'es';
        case 'ca-ES': return 'ca';
        case 'gl-ES': return 'gl';
        case 'en-US':
        default: return 'en';
    }
}
