import { Lang, LedgerEntryDto, TransactionRow, translateCategory, translateMoneyType } from '../../../shared';

export function mapLedgerEntriesToRows(entries: LedgerEntryDto[], lang: Lang): TransactionRow[] {
  return (entries ?? []).map((e: any) => {
    const categoryRaw = e.category ?? null;
    const paymentRaw = (e.accountType as any) ?? null;

    return {
      id: String(e.id ?? e.entryId ?? crypto.randomUUID()),
      note: e.note ?? '—',
      subtitle: '',
      category: categoryRaw,
      categoryLabel: translateCategory(categoryRaw, lang),
      paymentMethod: paymentRaw,
      paymentMethodLabel: translateMoneyType(paymentRaw, lang),
      currency: e.currency ?? 'EUR',
      amount: Number(e.amount ?? 0) * (e.type === 'EXPENSE' ? -1 : 1),
      date: (e.occursAt ?? e.createdAt ?? new Date()).toString(),
      type: e.type,
    };
  });
}
