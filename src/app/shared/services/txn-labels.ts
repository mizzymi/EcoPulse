import { Lang } from './language.service';

export type DefaultCategoryKey =
    | 'FOOD'
    | 'TRANSPORT'
    | 'RENT'
    | 'SHOPPING'
    | 'UTILITIES'
    | 'FUN'
    | 'HEALTH'
    | 'SALARY'
    | 'PETS';

// Money type labels (your MoneyType enum)
const moneyTypeLabels: Record<Lang, Record<string, string>> = {
    en: { CASH: 'Cash', BANK: 'Bank', CARD: 'Card', OTHER: 'Other' },
    es: { CASH: 'Efectivo', BANK: 'Banco', CARD: 'Tarjeta', OTHER: 'Otro' },
    ca: { CASH: 'Efectiu', BANK: 'Banc', CARD: 'Targeta', OTHER: 'Altres' },
    gl: { CASH: 'Efectivo', BANK: 'Banco', CARD: 'Tarxeta', OTHER: 'Outros' },
};

// Default category labels (front-only)
const categoryLabels: Record<Lang, Record<DefaultCategoryKey, string>> = {
    en: {
        FOOD: 'Food',
        TRANSPORT: 'Transport',
        RENT: 'Rent',
        SHOPPING: 'Shopping',
        UTILITIES: 'Utilities',
        FUN: 'Entertainment',
        HEALTH: 'Health',
        SALARY: 'Salary',
        PETS: 'Pets',
    },
    es: {
        FOOD: 'Comida',
        TRANSPORT: 'Transporte',
        RENT: 'Alquiler',
        SHOPPING: 'Compras',
        UTILITIES: 'Suministros',
        FUN: 'Ocio',
        HEALTH: 'Salud',
        SALARY: 'Salario',
        PETS: 'Mascotas',
    },
    ca: {
        FOOD: 'Menjar',
        TRANSPORT: 'Transport',
        RENT: 'Lloguer',
        SHOPPING: 'Compres',
        UTILITIES: 'Subministraments',
        FUN: 'Oci',
        HEALTH: 'Salut',
        SALARY: 'Sou',
        PETS: 'Mascotes',
    },
    gl: {
        FOOD: 'Comida',
        TRANSPORT: 'Transporte',
        RENT: 'Aluguer',
        SHOPPING: 'Compras',
        UTILITIES: 'Subministracións',
        FUN: 'Lecer',
        HEALTH: 'Saúde',
        SALARY: 'Salario',
        PETS: 'Mascotas',
    },
};

export function translateMoneyType(raw: string | null | undefined, lang: Lang): string {
    const key = (raw ?? '').trim().toUpperCase();
    if (!key) return '—';
    return moneyTypeLabels[lang][key] ?? key;
}

/**
 * Translates category.
 * - If raw is one of DefaultCategoryKey -> returns localized label.
 * - Otherwise returns raw (uppercased) or '—' if empty.
 */
export function translateCategory(raw: string | null | undefined, lang: Lang): string {
    const key = (raw ?? '').trim().toUpperCase();
    if (!key) return '—';

    // If it matches our default category enum, translate it
    if (key in categoryLabels[lang]) {
        return categoryLabels[lang][key as DefaultCategoryKey];
    }

    // Otherwise, keep whatever backend/user sent
    return key;
}
