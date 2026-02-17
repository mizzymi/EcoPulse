import { CommonModule } from '@angular/common';
import { Component, computed, effect, inject, signal } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { catchError, map, of, switchMap, startWith } from 'rxjs';

import { ApiService, SavingsGoalDto, SavingsGoalSummaryDto, SavingsTxnDto, SavingsTxnType, Container, LangSwitcher, HouseHoldSelector, ConfirmDialogService, ToastService } from '../../shared/';
import { SavingsFacade } from '../savings/data/savings.facade';
import { SavingIdHeader, SavingIdSummary, SavingIdTxnsList, SavingIdEditForm, SavingIdTxnForm } from "./components";
import { BreakpointObserver } from '@angular/cdk/layout';

type LoadState<T> = { loading: boolean; error: string | null; data: T };

@Component({
  selector: 'app-saving-id',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, Container, LangSwitcher, HouseHoldSelector, SavingIdHeader, SavingIdSummary, SavingIdTxnsList, SavingIdEditForm, SavingIdTxnForm],
  templateUrl: './saving-id.html',
})
export class SavingId {
  private bp = inject(BreakpointObserver);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly api = inject(ApiService);
  private readonly confirm = inject(ConfirmDialogService);
  private readonly toast = inject(ToastService);

  readonly facade = inject(SavingsFacade);
  isSmall = toSignal(this.bp.observe('(max-width: 1023px)').pipe(map((r) => r.matches)), { initialValue: false });
  readonly goalId = signal<string>('');

  private readonly _refreshTick = signal(0);
  readonly refresh = () => this._refreshTick.update((n) => n + 1);

  readonly busy = signal(false);

  readonly householdId = computed(() => this.facade.householdId());
  readonly hasHousehold = computed(() => !!this.householdId());
  private getLangFromUrl(): string {
    const first = this.router.url.split('/').filter(Boolean)[0];
    return first || 'ca-ES';
  }

  private goDashboard() {
    const lang = this.getLangFromUrl();
    this.router.navigate(['/', lang, 'dashboard']);
  }

  private bootstrapHouseholdFromGoal() {
    const goalId = this.goalId();
    if (!goalId) return this.goDashboard();

    if (this.hasHousehold()) return;

    this.api.getSavingsGoalById(goalId).subscribe({
      next: (goal) => {
        this.facade.householdId.set(goal.householdId);
        this.refresh();
      },
      error: () => {
        this.goDashboard();
      },
    });
  }

  private readonly _trigger$ = toObservable(
    computed(() => ({
      householdId: this.householdId(),
      goalId: this.goalId(),
      tick: this._refreshTick(),
    })),
  );

  private readonly _summaryState = toSignal(
    this._trigger$.pipe(
      switchMap(({ householdId, goalId }) => {
        if (!householdId || !goalId) {
          return of<LoadState<SavingsGoalSummaryDto | null>>({ loading: false, error: null, data: null });
        }

        return this.api.savingsGoalSummary(householdId, goalId).pipe(
          map((data) => ({ loading: false, error: null, data })),
          catchError((e: any) => {
            const msg =
              typeof e?.message === 'string' && e.message.trim()
                ? e.message
                : $localize`:@@savings.err.loadFailed:Failed to load data`;
            this.toast.error(msg);
            return of<LoadState<SavingsGoalSummaryDto | null>>({ loading: false, error: msg, data: null });
          }),
          startWith({ loading: true, error: null, data: null }),
        );
      }),
    ),
    { initialValue: { loading: true, error: null, data: null } as LoadState<SavingsGoalSummaryDto | null> },
  );

  readonly summaryLoading = computed(() => this._summaryState().loading);
  readonly summary = computed(() => this._summaryState().data);

  private readonly _txnsState = toSignal(
    this._trigger$.pipe(
      switchMap(({ householdId, goalId }) => {
        if (!householdId || !goalId) {
          return of<LoadState<SavingsTxnDto[]>>({ loading: false, error: null, data: [] });
        }

        return this.api.listSavingsTxns(householdId, goalId).pipe(
          map((rows) => ({ loading: false, error: null, data: rows ?? [] })),
          catchError((e: any) => {
            const msg =
              typeof e?.message === 'string' && e.message.trim()
                ? e.message
                : $localize`:@@savings.err.loadTxnsFailed:Failed to load transactions`;
            this.toast.error(msg);
            return of<LoadState<SavingsTxnDto[]>>({ loading: false, error: msg, data: [] });
          }),
          startWith({ loading: true, error: null, data: [] }),
        );
      }),
    ),
    { initialValue: { loading: true, error: null, data: [] } as LoadState<SavingsTxnDto[]> },
  );

  readonly txnsLoading = computed(() => this._txnsState().loading);
  readonly txns = computed(() => this._txnsState().data);

  readonly goal = computed(() => (this.summary() as any)?.goal as SavingsGoalDto | undefined);
  readonly saved = computed(() => Number((this.summary() as any)?.saved ?? 0));
  readonly target = computed(() => Number(this.goal()?.target ?? 0));

  readonly progressPct = computed(() => {
    const t = this.target();
    if (!t || t <= 0) return 0;
    return Math.max(0, Math.min(100, Math.round((this.saved() / t) * 100)));
  });

  constructor() {
    effect(() => {
      this.goalId.set(this.route.snapshot.paramMap.get('id') ?? '');
      this.bootstrapHouseholdFromGoal();
    });
  }

  onSaveGoal(dto: { name?: string; target?: number | string; deadline?: string | Date | null }) {
    const householdId = this.householdId();
    const goalId = this.goalId();

    if (!householdId) {
      this.toast.error($localize`:@@savings.err.noHousehold:No household selected`);
      return;
    }

    this.busy.set(true);
    this.api.updateSavingsGoal(householdId, goalId, dto).subscribe({
      next: () => {
        this.busy.set(false);
        this.toast.success($localize`:@@common.saved:Saved`);
        this.refresh();
      },
      error: (e: any) => {
        this.busy.set(false);
        const msg =
          typeof e?.message === 'string' && e.message.trim()
            ? e.message
            : $localize`:@@savings.err.saveFailed:Failed to save changes`;
        this.toast.error(msg);
      },
    });
  }

  async onDeleteGoal() {
    const householdId = this.householdId();
    const goalId = this.goalId();

    if (!householdId) {
      this.toast.error($localize`:@@savings.err.noHousehold:No household selected`);
      return;
    }

    const ok = await this.confirm.confirm({
      title: $localize`:@@savings.goal.deleteConfirm.title:Delete goal`,
      message: $localize`:@@savings.goal.deleteConfirm.message:This action cannot be undone.`,
      cancelText: $localize`:@@common.cancel:Cancel`,
      confirmText: $localize`:@@common.delete:Delete`,
      tone: 'danger',
    });

    if (!ok) return;

    this.busy.set(true);
    this.api.deleteSavingsGoal(householdId, goalId).subscribe({
      next: () => {
        this.busy.set(false);
        this.toast.success($localize`:@@savings.goal.deleted:Goal deleted`);
        this.router.navigate(['/savings']);
      },
      error: (e: any) => {
        this.busy.set(false);
        const msg =
          typeof e?.message === 'string' && e.message.trim()
            ? e.message
            : $localize`:@@savings.err.deleteFailed:Failed to delete goal`;
        this.toast.error(msg);
      },
    });
  }

  onAddTxn(dto: { type: SavingsTxnType; amount: number | string; note?: string; occursAt?: string | Date }) {
    const householdId = this.householdId();
    const goalId = this.goalId();

    if (!householdId) {
      this.toast.error($localize`:@@savings.err.noHousehold:No household selected`);
      return;
    }

    this.busy.set(true);
    this.api.addSavingsTxn(householdId, goalId, dto).subscribe({
      next: () => {
        this.busy.set(false);
        this.toast.success($localize`:@@savings.txn.added:Transaction added`);
        this.refresh();
      },
      error: (e: any) => {
        this.busy.set(false);
        const msg =
          typeof e?.message === 'string' && e.message.trim()
            ? e.message
            : $localize`:@@savings.err.addTxnFailed:Failed to add transaction`;
        this.toast.error(msg);
      },
    });
  }

  trackTxn = (_: number, t: SavingsTxnDto) => t.id;

  async onDeleteTxn(txn: SavingsTxnDto) {
    const householdId = this.householdId();
    const goalId = this.goalId();

    if (!householdId) {
      this.toast.error($localize`:@@savings.err.noHousehold:No household selected`);
      return;
    }

    const ok = await this.confirm.confirm({
      title: $localize`:@@savingId.txn.deleteConfirm.title:Delete transaction`,
      message: $localize`:@@savingId.txn.deleteConfirm.message:This action cannot be undone.`,
      cancelText: $localize`:@@common.cancel:Cancel`,
      confirmText: $localize`:@@common.delete:Delete`,
      tone: 'danger',
    });

    if (!ok) return;

    this.busy.set(true);
    this.api.deleteSavingsTxn(householdId, goalId, txn.id).subscribe({
      next: () => {
        this.busy.set(false);
        this.toast.success($localize`:@@savingId.txn.deleted:Transaction deleted`);
        this.refresh();
      },
      error: (e: any) => {
        this.busy.set(false);
        const msg =
          typeof e?.message === 'string' && e.message.trim()
            ? e.message
            : $localize`:@@savingId.txn.deleteFailed:Failed to delete transaction`;
        this.toast.error(msg);
      },
    });
  }
}
