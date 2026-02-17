import {
  Component,
  EventEmitter,
  HostListener,
  Input,
  Output,
  computed,
  inject,
  signal,
} from '@angular/core';
import { CommonModule, NgClass, NgFor, NgIf } from '@angular/common';
import {
  BadgeDollarSign,
  Bus,
  HeartPulse,
  Home,
  Lightbulb,
  LucideAngularModule,
  LucideIconData,
  PawPrint,
  ShoppingBag,
  Smile,
  Utensils,
  ArrowDown,
  ArrowUp,
  X,
  Banknote,
  CreditCard,
  Landmark,
  Plus,
  Check,
} from 'lucide-angular';

import { TransactionRow } from '../../../shared';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { map } from 'rxjs';

export type NewEntryType = 'EXPENSE' | 'INCOME';
export type PaymentMethod = 'CASH' | 'CARD' | 'BANK';

export type CategoryItem = {
  id: string; // stable id for list rendering
  label: string; // UI label (localized for defaults, user-provided for existing)
  icon: LucideIconData;
  key?: string; // optional stable key for defaults
};

export type NewEntryPayload = {
  type: NewEntryType;
  amount: number;
  currency: string;
  paymentMethod: PaymentMethod;
  categoryLabel: string | null;
  dateISO: string;
  recurring: boolean;
  note: string;
};

type DefaultCategoryKey =
  | 'FOOD'
  | 'TRANSPORT'
  | 'RENT'
  | 'SHOPPING'
  | 'UTILITIES'
  | 'FUN'
  | 'HEALTH'
  | 'SALARY'
  | 'PETS';

@Component({
  selector: 'app-new-entry-modal',
  standalone: true,
  imports: [CommonModule, NgIf, NgFor, LucideAngularModule, NgClass],
  templateUrl: './new-entry-modal.html',
})
export class NewEntryModal {
  private bp = inject(BreakpointObserver);

  private _open = false;
  private _initial: Partial<NewEntryPayload> | null = null;

  // Responsive
  isSmall = toSignal(this.bp.observe('(max-width: 639px)').pipe(map((r) => r.matches)), {
    initialValue: false,
  });

  // Custom category input state
  readonly customCategoryText = signal<string>('');
  readonly customMode = signal<boolean>(false);
  readonly isCustomCategory = computed(() => this.customMode());

  @Input()
  set open(value: boolean) {
    this._open = value;

    if (!value) return;

    this.resetForm();
    const init = this.initial;
    if (init) this.applyInitial(init);
  }
  get open() {
    return this._open;
  }

  @Input()
  set initial(v: Partial<NewEntryPayload> | null) {
    this._initial = v;

    if (!this.open) return;

    this.resetForm();
    if (v) this.applyInitial(v);
  }
  get initial() {
    return this._initial;
  }

  @Input() mode: 'CREATE' | 'EDIT' = 'CREATE';
  @Input() existingRows: TransactionRow[] = [];
  @Input() defaultCurrency = 'EUR';

  @Output() close = new EventEmitter<void>();
  @Output() save = new EventEmitter<NewEntryPayload>();

  readonly type = signal<NewEntryType>('EXPENSE');
  readonly paymentMethod = signal<PaymentMethod>('CASH');
  readonly selectedCategoryLabel = signal<string | null>(null);
  readonly recurring = signal(false);
  readonly note = signal('');

  private readonly _amount = signal<number>(0);
  readonly amountText = signal<string>('');

  readonly dateISO = signal<string>(this.toISODate(new Date()));
  readonly date = computed(() => new Date(this.dateISO()));
  readonly currency = computed(() => this.defaultCurrency || 'EUR');

  /**
   * IMPORTANT for EN/ES/CA:
   * - Default categories are LOCALIZED via $localize (Angular i18n extracts these).
   * - Icon selection for defaults is done by stable key (no string matching needed).
   * - Existing/user categories keep their original label; icon is inferred via multilingual keyword buckets.
   */
  readonly categories = computed<CategoryItem[]>(() => {
    // Localized defaults (English source; Spanish/Catalan via messages.*.xlf)
    const defaults: Array<{ key: DefaultCategoryKey; label: string }> = [
      { key: 'FOOD', label: $localize`:@@tx.cat.food:Food` },
      { key: 'TRANSPORT', label: $localize`:@@tx.cat.transport:Transport` },
      { key: 'RENT', label: $localize`:@@tx.cat.rent:Rent` },
      { key: 'SHOPPING', label: $localize`:@@tx.cat.shopping:Shopping` },
      { key: 'UTILITIES', label: $localize`:@@tx.cat.utilities:Utilities` },
      { key: 'FUN', label: $localize`:@@tx.cat.fun:Fun` },
      { key: 'HEALTH', label: $localize`:@@tx.cat.health:Health` },
      { key: 'SALARY', label: $localize`:@@tx.cat.salary:Salary` },
      { key: 'PETS', label: $localize`:@@tx.cat.pets:Pets` },
    ];

    // Pull labels from existing rows (user categories) – keep as-is
    const fromExisting = (this.existingRows ?? [])
      .map((r) => (r?.category ?? '').trim())
      .filter(Boolean);

    // Merge: existing first (so user sees their real categories), then defaults
    const merged: CategoryItem[] = [];

    // Add existing categories (dedupe by normalized label)
    const seen = new Set<string>();
    for (const label of fromExisting) {
      const norm = this.normalizeCategory(label);
      if (!norm || seen.has(norm)) continue;
      seen.add(norm);

      merged.push({
        id: this.slug(label),
        label,
        icon: this.iconForCategory(label), // multilingual inference
      });
    }

    // Add defaults if not already covered
    for (const d of defaults) {
      const norm = this.normalizeCategory(d.label);
      if (!norm || seen.has(norm)) continue;
      seen.add(norm);

      merged.push({
        id: d.key,
        key: d.key,
        label: d.label,
        icon: this.iconForDefaultKey(d.key),
      });
    }

    return merged.slice(0, 9);
  });

  readonly canSave = computed(() => this._amount() > 0 && !!this.selectedCategoryLabel());

  private resetForm() {
    this.customMode.set(false);
    this.customCategoryText.set('');

    this.type.set('EXPENSE');
    this.paymentMethod.set('CASH');
    this.selectedCategoryLabel.set(null);
    this.recurring.set(false);
    this.note.set('');

    this._amount.set(0);
    this.amountText.set('');

    this.dateISO.set(this.toISODate(new Date()));
  }

  private applyInitial(init: Partial<NewEntryPayload>) {
    if (init.type) this.type.set(init.type);
    if (init.paymentMethod) this.paymentMethod.set(init.paymentMethod);

    if (init.categoryLabel !== undefined) {
      this.selectedCategoryLabel.set(init.categoryLabel ?? null);
    }

    if (init.recurring !== undefined) this.recurring.set(!!init.recurring);
    if (init.note !== undefined) this.note.set(init.note ?? '');
    if (init.dateISO) this.dateISO.set(init.dateISO);

    if (init.amount !== undefined) {
      const v = Number(init.amount);
      const safe = Number.isFinite(v) ? v : 0;
      this._amount.set(safe);
      this.amountText.set(safe ? String(safe) : '');
    }
  }

  @HostListener('document:keydown.escape')
  onEsc() {
    if (this.open) this.close.emit();
  }

  onBackdrop() {
    this.close.emit();
  }

  setType(v: NewEntryType) {
    this.type.set(v);
  }

  onAmountInput(raw: string) {
    const clean = (raw ?? '').replace(',', '.').replace(/[^0-9.]/g, '');
    const parts = clean.split('.');
    const normalized = parts.length <= 1 ? clean : `${parts[0]}.${parts.slice(1).join('')}`;

    const num = Number(normalized);
    const value = Number.isFinite(num) ? num : 0;

    this._amount.set(value);
    this.amountText.set(normalized.length ? normalized : '');
  }

  onDateChange(v: string) {
    if (!v) return;
    this.dateISO.set(v);
  }

  openDatePicker(input: HTMLInputElement) {
    if (typeof (input as any).showPicker === 'function') {
      (input as any).showPicker();
      return;
    }
    input.focus();
    input.click();
  }

  selectCategory(label: string) {
    this.customMode.set(false);
    this.customCategoryText.set('');
    this.selectedCategoryLabel.set(label);
  }

  onSave() {
    this.save.emit({
      type: this.type(),
      amount: this._amount(),
      currency: this.currency(),
      paymentMethod: this.paymentMethod(),
      categoryLabel: this.selectedCategoryLabel(),
      dateISO: this.dateISO(),
      recurring: this.recurring(),
      note: this.note(),
    });
  }

  onCustomCategory() {
    this.customMode.set(true);
    this.selectedCategoryLabel.set(null);
    this.customCategoryText.set('');
  }

  onCustomCategoryInput(v: string) {
    this.customCategoryText.set(v ?? '');
  }

  applyCustomCategory() {
    const value = this.customCategoryText().trim();
    if (!value) return;

    this.selectedCategoryLabel.set(value);
    this.customMode.set(false);
  }

  private toISODate(d: Date) {
    const yyyy = String(d.getFullYear());
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  private slug(s: string) {
    return (s ?? '')
      .toLowerCase()
      .trim()
      .replace(/\s+/g, '-')
      .replace(/[^\w-]/g, '');
  }

  /**
   * Normalize for matching across EN/ES/CA (removes accents too).
   */
  private normalizeCategory(s: string): string {
    const base = (s ?? '')
      .normalize('NFD') // split accents
      .replace(/[\u0300-\u036f]/g, '') // remove accents
      .toLowerCase();

    return base
      .replace(/[_/\\-]+/g, ' ')
      .replace(/[^a-z0-9 ]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Default categories: map by KEY (stable, language independent).
   */
  private iconForDefaultKey(key: DefaultCategoryKey): LucideIconData {
    switch (key) {
      case 'FOOD':
        return this.utensils;
      case 'TRANSPORT':
        return this.bus;
      case 'RENT':
        return this.home;
      case 'SHOPPING':
        return this.shoppingBag;
      case 'UTILITIES':
        return this.lightbulb;
      case 'FUN':
        return this.smile;
      case 'HEALTH':
        return this.heartPulse;
      case 'SALARY':
        return this.badgeDollarSign;
      case 'PETS':
        return this.paw;
      default:
        return this.badgeDollarSign;
    }
  }

  /**
   * User/existing categories: infer icon by multilingual keyword buckets (EN/ES/CA).
   * Keep these keywords as a matching dictionary (NOT i18n UI strings).
   */
  private iconForCategory(label: string): LucideIconData {
    const l = this.normalizeCategory(label);

    const buckets: Array<[string[], LucideIconData]> = [
      [
        [
          // EN
          'food', 'groceries', 'grocery', 'supermarket', 'market',
          'restaurant', 'dining', 'takeaway', 'take out', 'delivery',
          'coffee', 'cafe', 'bar',
        ]
          // ES
          .concat([
            'comida', 'alimentacion', 'alimentos', 'supermercado', 'mercado',
            'restaurante', 'cena', 'para llevar', 'llevar', 'reparto',
            'domicilio', 'cafeteria', 'bar',
          ])
          // CA
          .concat([
            'menjar', 'alimentacio', 'aliments', 'supermercat', 'mercat',
            'restaurant', 'sopar', 'per emportar', 'emportar', 'repartiment',
            'a domicili', 'cafe', 'cafeteria', 'bar',
          ])
          // GL
          .concat([
            'comida', 'alimentacion', 'alimentos', 'supermercado', 'mercado',
            'restaurante', 'cafe', 'cafeteria', 'bar', 'para levar', 'a domicilio',
          ]),
        this.utensils,
      ],

      [
        [
          // EN
          'transport', 'transportation', 'commute', 'metro', 'subway', 'train', 'bus',
          'taxi', 'uber', 'lyft', 'ride', 'parking', 'toll',
          'fuel', 'gasoline', 'gas', 'diesel',
        ]
          // ES
          .concat([
            'transporte', 'desplazamiento', 'metro', 'tren', 'autobus', 'bus',
            'taxi', 'uber', 'aparcamiento', 'peaje',
            'combustible', 'gasolina', 'gasoil', 'diesel',
          ])
          // CA
          .concat([
            'transport', 'desplacament', 'metro', 'tren', 'autobus', 'bus',
            'taxi', 'uber', 'aparcament', 'peatge',
            'combustible', 'benzina', 'gasoil', 'diesel',
          ])
          // GL
          .concat([
            'transporte', 'desprazamento', 'metro', 'tren', 'autobus', 'bus',
            'taxi', 'aparcamento', 'peaxe',
            'combustible', 'gasolina', 'gasoleo', 'diesel',
          ]),
        this.bus,
      ],

      [
        [
          // EN
          'rent', 'rental', 'mortgage', 'home', 'house', 'apartment', 'housing',
        ]
          // ES
          .concat(['alquiler', 'renta', 'hipoteca', 'casa', 'hogar', 'piso', 'vivienda'])
          // CA
          .concat(['lloguer', 'hipoteca', 'casa', 'llar', 'pis', 'habitatge'])
          // GL
          .concat(['aluguer', 'hipoteca', 'casa', 'fogar', 'piso', 'vivenda']),
        this.home,
      ],

      [
        [
          // EN
          'shopping', 'shop', 'store', 'clothes', 'clothing', 'shoes', 'fashion',
          'electronics', 'amazon',
        ]
          // ES
          .concat(['compras', 'compra', 'tienda', 'ropa', 'zapatos', 'moda', 'electronica', 'amazon'])
          // CA
          .concat(['compres', 'compra', 'botiga', 'roba', 'sabates', 'moda', 'electronica', 'amazon'])
          // GL
          .concat(['compras', 'compra', 'tenda', 'roupa', 'zapatos', 'moda', 'electronica', 'amazon']),
        this.shoppingBag,
      ],

      [
        [
          // EN
          'utilities', 'utility', 'electric', 'electricity', 'water', 'internet', 'wifi',
          'phone', 'mobile', 'cell', 'gas bill', 'heating', 'bill', 'bills',
        ]
          // ES
          .concat([
            'servicios', 'suministros', 'luz', 'electricidad', 'agua', 'internet', 'wifi',
            'telefono', 'movil', 'factura gas', 'calefaccion', 'factura', 'facturas',
          ])
          // CA
          .concat([
            'subministraments', 'serveis', 'llum', 'electricitat', 'aigua', 'internet', 'wifi',
            'telefon', 'mobil', 'factura gas', 'calefaccio', 'factura', 'factures',
          ])
          // GL
          .concat([
            'servizos', 'subministracions', 'luz', 'electricidade', 'auga', 'internet', 'wifi',
            'telefono', 'movil', 'factura gas', 'calefaccion', 'factura', 'facturas',
          ]),
        this.lightbulb,
      ],

      [
        [
          // EN
          'fun', 'entertainment', 'movies', 'cinema', 'games', 'gaming', 'party',
          'netflix', 'spotify', 'hbo', 'prime', 'disney',
        ]
          // ES
          .concat(['ocio', 'entretenimiento', 'peliculas', 'cine', 'juegos', 'fiesta', 'netflix', 'spotify', 'hbo', 'prime', 'disney'])
          // CA
          .concat(['oci', 'entreteniment', 'pelicules', 'cinema', 'jocs', 'festa', 'netflix', 'spotify', 'hbo', 'prime', 'disney'])
          // GL
          .concat(['lecer', 'entretemento', 'peliculas', 'cine', 'xogos', 'festa', 'netflix', 'spotify']),
        this.smile,
      ],

      [
        [
          // EN
          'health', 'medical', 'doctor', 'hospital', 'pharmacy', 'dentist',
          'gym', 'fitness', 'therapy',
        ]
          // ES
          .concat(['salud', 'medico', 'medica', 'doctor', 'hospital', 'farmacia', 'dentista', 'gimnasio', 'fitness', 'terapia'])
          // CA
          .concat(['salut', 'metge', 'metgessa', 'doctor', 'hospital', 'farmacia', 'dentista', 'gimnas', 'fitness', 'terapia'])
          // GL
          .concat(['saude', 'medico', 'medica', 'doctor', 'hospital', 'farmacia', 'dentista', 'ximnasio', 'terapia']),
        this.heartPulse,
      ],

      [
        [
          // EN
          'salary', 'payroll', 'income', 'wage', 'paycheck', 'bonus',
        ]
          // ES
          .concat(['salario', 'nomina', 'ingresos', 'sueldo', 'paga', 'bonus'])
          // CA
          .concat(['salari', 'nomina', 'ingressos', 'sou', 'paga', 'bonus'])
          // GL
          .concat(['salario', 'nomina', 'ingresos', 'soldos', 'paga', 'bonus']),
        this.badgeDollarSign,
      ],

      [
        [
          // EN
          'pets', 'pet', 'dog', 'cat', 'vet', 'veterinary',
        ]
          // ES
          .concat(['mascotas', 'mascota', 'perro', 'gato', 'veterinario', 'veterinaria'])
          // CA
          .concat(['mascotes', 'mascota', 'gos', 'gat', 'veterinari', 'veterinaria'])
          // GL
          .concat(['mascotas', 'mascota', 'can', 'cans', 'gato', 'veterinario', 'veterinaria']),
        this.paw,
      ],
    ];

    for (const [keys, icon] of buckets) {
      if (keys.some((k) => l.includes(this.normalizeCategory(k)))) return icon;
    }

    return this.badgeDollarSign;
  }

  // Icons
  public utensils = Utensils;
  public bus = Bus;
  public home = Home;
  public shoppingBag = ShoppingBag;
  public lightbulb = Lightbulb;
  public smile = Smile;
  public heartPulse = HeartPulse;
  public badgeDollarSign = BadgeDollarSign;
  public paw = PawPrint;

  public arrowDown = ArrowDown;
  public arrowUp = ArrowUp;
  public x = X;

  public banknote = Banknote;
  public creditCard = CreditCard;
  public landmark = Landmark;

  public plus = Plus;
  public check = Check;
}
