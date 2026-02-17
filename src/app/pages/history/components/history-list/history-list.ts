import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
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
  Pencil,
  Trash2,
} from 'lucide-angular';

@Component({
  selector: 'app-history-list',
  standalone: true,
  imports: [CommonModule, LucideAngularModule],
  templateUrl: './history-list.html',
})
export class HistoryList {
  @Input() items: any[] = [];
  @Input() formatMoney!: (amount: number, currency: string) => string;

  @Output() edit = new EventEmitter<any>();
  @Output() remove = new EventEmitter<any>();

  // action icons
  public pencil = Pencil;
  public trash = Trash2;

  // category icons
  public utensils = Utensils;
  public bus = Bus;
  public home = Home;
  public shoppingBag = ShoppingBag;
  public lightbulb = Lightbulb;
  public smile = Smile;
  public heartPulse = HeartPulse;
  public badgeDollarSign = BadgeDollarSign;
  public paw = PawPrint;

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

  iconForCategory(label?: string | null): LucideIconData {
    const l = this.normalizeCategory(label ?? '');

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
      if (keys.some(k => l.includes(this.normalizeCategory(k)))) return icon;
    }

    return this.badgeDollarSign;
  }
}
