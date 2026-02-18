import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DOCUMENT } from '@angular/common';
import { Locale } from '../../services';
@Component({
  selector: 'app-lang-switcher',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './lang-switcher.html',
})
export class LangSwitcher {
  private doc = inject(DOCUMENT);

  readonly supported: Locale[] = ['en-US', 'es-ES', 'ca-ES', 'gl-ES'];

  get currentLocale(): Locale {
    const path = this.doc.location.pathname;
    const first = path.split('/').filter(Boolean)[0] as Locale | undefined;
    return this.supported.includes(first as Locale) ? (first as Locale) : 'en-US';
  }

  switch(locale: Locale) {
    const { origin, pathname, search, hash } = this.doc.location;

    const parts = pathname.split('/').filter(Boolean);
    const first = parts[0] as Locale | undefined;
    const rest = this.supported.includes(first as Locale) ? parts.slice(1) : parts;

    const newPath = `/${locale}/index.html`;

    this.doc.location.href = origin + newPath + search + hash;
  }
}