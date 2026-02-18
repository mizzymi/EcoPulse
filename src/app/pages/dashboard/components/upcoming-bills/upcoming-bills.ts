import { Component, inject, Input } from '@angular/core';
import { NgFor, NgIf } from '@angular/common';
import {
  LucideAngularModule,
  LucideIconData,
  Utensils,
  Bus,
  Home,
  ShoppingBag,
  Lightbulb,
  Smile,
  HeartPulse,
  BadgeDollarSign,
  PawPrint,
} from 'lucide-angular';
import { Router } from '@angular/router';

export interface UpcomingBill {
  title: string;
  subtitle: string;
  amount: number;
  tag?: string;
  /** store category/name, not icon object */
  category?: string | null;
  occursAt: Date;
}

@Component({
  selector: 'app-upcoming-bills',
  standalone: true,
  imports: [NgFor, NgIf, LucideAngularModule],
  templateUrl: './upcoming-bills.html',
})
export class UpcomingBills {
  private readonly router = inject(Router);
  @Input({ required: true }) bills!: UpcomingBill[];
  @Input() header = 'Upcoming Bills';
  @Input() actionText = 'See All';

  // icons
  public utensils = Utensils;
  public bus = Bus;
  public home = Home;
  public shoppingBag = ShoppingBag;
  public lightbulb = Lightbulb;
  public smile = Smile;
  public heartPulse = HeartPulse;
  public badgeDollarSign = BadgeDollarSign;
  public paw = PawPrint;

  public goRecurrent() {
    this.router.navigate(['/recurrent']);
  }
  /**
    * Normalize for matching across EN/ES/CA (removes accents too).
    */
  private normalizeCategory(s: unknown): string {
    const base = String(s ?? '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase();

    return base
      .replace(/[_/\\-]+/g, ' ')
      .replace(/[^a-z0-9 ]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  public iconForCategory(label: unknown): LucideIconData {
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
          .concat(['lecer', 'entretemento', 'peliculas', 'cine', 'xogos', 'festa', 'netflix', 'spotify'])
          // EN
          .concat([
            'subscription', 'subscriptions', 'membership', 'memberships',
            'streaming', 'plan',
          ])
          // ES
          .concat([
            'suscripcion', 'suscripciones', 'suscripción', 'suscripciones',
            'membresia', 'membresias', 'membresía', 'membresías',
          ])
          // CA
          .concat([
            'subscripcio', 'subscripcions', 'subscripció', 'subscripcions',
            'membresia', 'membresies', 'membresía', 'membresies',
          ])
          // GL
          .concat([
            'subscricion', 'subscricions', 'subscrición', 'subscricións',
            'membresia', 'membresias', 'membresía', 'membresías',
          ]),
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

  formatAmount(v: number): string {
    const abs = Math.abs(v);
    const formatted = abs.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    return (v < 0 ? '-' : '+') + '$' + formatted;
  }
}
