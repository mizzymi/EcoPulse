import { LedgerEntryDto, TransactionRow } from '../../../shared';

export function mapLedgerEntriesToRows(entries: LedgerEntryDto[]): TransactionRow[] {
    return (entries ?? []).map((e: any) => ({
        id: String(e.id ?? e.entryId ?? crypto.randomUUID()),
        note: e.note ?? '—',
        subtitle: '',
        category: e.category ?? null,
        paymentMethod: (e.accountType as any) ?? null,
        currency: e.currency ?? 'EUR',
        amount: Number(e.amount ?? 0) * (e.type === 'EXPENSE' ? -1 : 1),
        date: e.occursAt ?? e.createdAt ?? new Date(),
        type: e.type,
    }));
}
