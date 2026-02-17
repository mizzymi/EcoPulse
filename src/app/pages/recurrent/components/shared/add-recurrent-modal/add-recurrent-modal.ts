import { CommonModule } from '@angular/common';
import {
  Component,
  EventEmitter,
  Output,
  inject,
  signal,
  computed,
  input,
  effect,
} from '@angular/core';
import { BreakpointObserver } from '@angular/cdk/layout';
import { toSignal } from '@angular/core/rxjs-interop';
import { finalize, map, startWith } from 'rxjs';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RecurrentFacade } from '../../../data/recurrent.facade';
import { LedgerEntryType, PlannedItemDto, RecurringDefDto, ToastService } from '../../../../../shared';

type AddTarget = 'PLANNED' | 'RECURRING';
type AddMode = 'CREATE' | 'EDIT';

@Component({
  selector: 'app-add-recurrent-modal',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './add-recurrent-modal.html',
})
export class AddRecurrentModal {
  private bp = inject(BreakpointObserver);
  private fb = inject(FormBuilder);
  private facade = inject(RecurrentFacade);
  private toast = inject(ToastService);
  readonly saving = signal(false);

  // Parent-owned inputs (read-only signals)
  open = input.required<boolean>();
  target = input<AddTarget>('PLANNED');
  mode = input<AddMode>('CREATE');
  editingPlanned = input<PlannedItemDto | null>(null);
  editingRecurring = input<RecurringDefDto | null>(null);

  // ✅ Local UI state (writable)
  readonly targetUi = signal<AddTarget>('PLANNED');
  readonly modeUi = signal<AddMode>('CREATE');

  @Output() close = new EventEmitter<void>();
  @Output() saved = new EventEmitter<void>();
  @Output() targetChange = new EventEmitter<'PLANNED' | 'RECURRING'>();
  @Output() savedTarget = new EventEmitter<'PLANNED' | 'RECURRING'>();

  setTarget(t: 'PLANNED' | 'RECURRING') {
    this.targetUi.set(t);
    this.targetChange.emit(t);
  }
  isSmall = toSignal(
    this.bp.observe('(max-height: 853px)').pipe(map((r) => r.matches)),
    { initialValue: false },
  );

  // UI state (signals)
  readonly type = signal<LedgerEntryType>('EXPENSE');
  readonly scheduleMode = signal<'DAY_OF_MONTH' | 'RRULE'>('DAY_OF_MONTH');

  // Planned form
  readonly plannedForm = this.fb.nonNullable.group({
    concept: ['', [Validators.required, Validators.maxLength(120)]],
    amount: [0, [Validators.required]],
    dueDate: ['', [Validators.required]],
    month: [''],
    category: [''],
    notes: [''],
  });

  // Recurring form
  readonly recurringForm = this.fb.nonNullable.group({
    concept: ['', [Validators.required, Validators.maxLength(120)]],
    amount: [0, [Validators.required]],
    dayOfMonth: [1 as number | null, [Validators.min(1), Validators.max(31)]],
    rrule: [''],
    category: [''],
    notes: [''],
  });

  readonly plannedValid = toSignal(
    this.plannedForm.statusChanges.pipe(
      startWith(this.plannedForm.status),
      map((s) => s === 'VALID'),
    ),
    { initialValue: this.plannedForm.valid },
  );

  readonly recurringValid = toSignal(
    this.recurringForm.statusChanges.pipe(
      startWith(this.recurringForm.status),
      map((s) => s === 'VALID'),
    ),
    { initialValue: this.recurringForm.valid },
  );

  // ✅ Use targetUi() (not target())
  readonly canSave = computed(() => {
    if (this.targetUi() === 'PLANNED') return this.plannedValid();

    if (!this.recurringValid()) return false;

    const amount = Number(this.recurringForm.controls.amount.value);
    return Number.isFinite(amount) && amount !== 0;
  });

  private buildScheduleCreateDto(): { dayOfMonth?: number; rrule?: string } {
    const r = this.recurringForm.getRawValue();

    if (this.scheduleMode() === 'DAY_OF_MONTH') {
      const raw = r.dayOfMonth;
      const d = typeof raw === 'number' ? raw : raw == null ? NaN : Number(raw);
      const safe = Number.isFinite(d) ? Math.max(1, Math.min(31, Math.trunc(d))) : 1;

      return { dayOfMonth: safe, rrule: undefined };
    }

    const rule = r.rrule?.trim() ? r.rrule.trim() : undefined;
    return { dayOfMonth: undefined, rrule: rule };
  }

  private buildScheduleUpdateDto():
    | { dayOfMonth: number | null; rrule?: undefined }
    | { rrule: string | null; dayOfMonth?: undefined } {

    const r = this.recurringForm.getRawValue();

    if (this.scheduleMode() === 'DAY_OF_MONTH') {
      const raw = r.dayOfMonth;
      const d = typeof raw === 'number' ? raw : raw == null ? NaN : Number(raw);
      const safe = Number.isFinite(d) ? Math.max(1, Math.min(31, Math.trunc(d))) : 1;

      return { dayOfMonth: safe, rrule: undefined };
    }

    const rule = r.rrule?.trim() ? r.rrule.trim() : null;

    return { rrule: rule, dayOfMonth: undefined };
  }

  public applyScheduleMode(mode: 'DAY_OF_MONTH' | 'RRULE', source: 'init' | 'user' = 'user') {
    this.scheduleMode.set(mode);

    const dayCtrl = this.recurringForm.controls.dayOfMonth;
    const rruleCtrl = this.recurringForm.controls.rrule;

    if (mode === 'DAY_OF_MONTH') {
      dayCtrl.setValidators([Validators.required, Validators.min(1), Validators.max(31)]);
      rruleCtrl.clearValidators();

      if (source !== 'init') rruleCtrl.setValue('');

      if (dayCtrl.value == null) dayCtrl.setValue(1);

      rruleCtrl.updateValueAndValidity();
      dayCtrl.updateValueAndValidity();
      this.recurringForm.updateValueAndValidity();
      return;
    }

    rruleCtrl.setValidators([Validators.required, Validators.maxLength(300)]);
    dayCtrl.clearValidators();

    if (source !== 'init') dayCtrl.setValue(null);

    rruleCtrl.updateValueAndValidity();
    dayCtrl.updateValueAndValidity();
    this.recurringForm.updateValueAndValidity();
  }

  constructor() {
    let wasOpen = false;
    effect(() => {
      const o = this.open();
      if (o && !wasOpen) {
        this.targetUi.set(this.target());
        this.modeUi.set(this.mode());
      }
      wasOpen = o;
    });

    effect(() => {
      if (!this.open()) return;

      const mode = this.modeUi();
      const target = this.targetUi();

      if (mode === 'EDIT') {
        if (target === 'PLANNED') {
          const p = this.editingPlanned();
          if (!p) return;

          this.type.set(p.type);
          this.plannedForm.reset({
            concept: p.concept ?? '',
            amount: Number(p.amount ?? 0),
            dueDate: (p.dueDate ?? '').slice(0, 10),
            month: (p.month ?? this.facade.month()) || this.facade.month(),
            category: p.category ?? '',
            notes: p.notes ?? '',
          });
          return;
        }

        if (target === 'RECURRING') {
          const r = this.editingRecurring();
          if (!r) return;
          this.type.set(r.type);

          this.recurringForm.reset({
            concept: r.concept ?? '',
            amount: Number(r.amount ?? 0),
            dayOfMonth: r.dayOfMonth ?? null,
            rrule: r.rrule ?? '',
            category: r.category ?? '',
            notes: r.notes ?? '',
          });

          const hasRrule = !!(r.rrule ?? '').trim();
          const hasDay = typeof r.dayOfMonth === 'number' && r.dayOfMonth >= 1 && r.dayOfMonth <= 31;

          const mode: 'DAY_OF_MONTH' | 'RRULE' =
            hasRrule ? 'RRULE' : 'DAY_OF_MONTH';

          this.applyScheduleMode(mode, 'init');

          if (!hasRrule && !hasDay) {
            this.recurringForm.controls.dayOfMonth.setValue(1);
            this.recurringForm.updateValueAndValidity();
          }
          return;
        }

        return;
      }

      this.type.set('EXPENSE');
      this.applyScheduleMode('DAY_OF_MONTH', 'init');

      this.plannedForm.reset({
        concept: '',
        amount: 0,
        dueDate: '',
        month: this.facade.month(),
        category: '',
        notes: '',
      });

      this.recurringForm.reset({
        concept: '',
        amount: 0,
        dayOfMonth: 1,
        rrule: '',
        category: '',
        notes: '',
      });
    });
  }

  onBackdrop(): void {
    this.close.emit();
  }

  setType(t: LedgerEntryType): void {
    this.type.set(t);
  }

  onNumberInput(scope: 'planned' | 'recurring', key: 'amount' | 'dayOfMonth', n: number): void {
    const v = Number.isFinite(n) ? n : null;

    if (scope === 'recurring') {
      if (key === 'amount') this.recurringForm.controls.amount.setValue((v ?? 0) as any);
      if (key === 'dayOfMonth') this.recurringForm.controls.dayOfMonth.setValue(v as any);
      return;
    }

    if (key === 'amount') this.plannedForm.controls.amount.setValue((v ?? 0) as any);
  }

  submit(): void {
    if (this.saving()) return;

    if (!this.canSave()) {
      if (this.targetUi() === 'PLANNED') this.plannedForm.markAllAsTouched();
      else this.recurringForm.markAllAsTouched();
      return;
    }

    this.saving.set(true);

    if (this.targetUi() === 'PLANNED') {
      const v = this.plannedForm.getRawValue();

      const req$ =
        this.modeUi() === 'CREATE'
          ? this.facade.createPlanned({
            concept: v.concept,
            amount: Number(v.amount),
            type: this.type(),
            dueDate: v.dueDate,
            month: v.month || this.facade.month(),
            category: v.category || undefined,
            notes: v.notes || undefined,
          })
          : (() => {
            const p = this.editingPlanned();
            if (!p) return null;
            return this.facade.updatePlanned(p.id, {
              concept: v.concept,
              amount: Number(v.amount),
              type: this.type(),
              dueDate: v.dueDate,
              month: v.month || null,
              category: v.category || null,
              notes: v.notes || null,
            });
          })();

      if (!req$) {
        this.saving.set(false);
        return;
      }

      req$
        .pipe(finalize(() => this.saving.set(false)))
        .subscribe({
          next: () => {
            this.toast.success(this.modeUi() === 'CREATE' ? 'Planned item created' : 'Planned item updated');
            this.savedTarget.emit(this.targetUi());
            this.saved.emit();
          },
          error: (e) => {
            this.toast.error(e?.message ?? 'Could not save planned item');
          },
        });

      return;
    }

    // =========================
    // RECURRING
    // =========================
    const r = this.recurringForm.getRawValue();

    const createSchedule = this.buildScheduleCreateDto();
    const updateSchedule = this.buildScheduleUpdateDto();

    const createPayload = {
      concept: r.concept,
      amount: Number(r.amount),
      type: this.type(),
      ...createSchedule,
      notes: r.notes || undefined,
      category: r.category || undefined,
    };

    const req$ =
      this.modeUi() === 'CREATE'
        ? this.facade.createRecurring(createPayload)
        : (() => {
          const rec = this.editingRecurring();
          if (!rec) return null;

          return this.facade.updateRecurring(rec.id, {
            concept: createPayload.concept,
            amount: createPayload.amount,
            type: createPayload.type,
            ...updateSchedule,
            notes: r.notes || null,
            category: r.category || null,
          });
        })();

    if (!req$) {
      this.saving.set(false);
      return;
    }

    req$
      .pipe(finalize(() => this.saving.set(false)))
      .subscribe({
        next: () => {
          this.toast.success('Recurring item updated');
          this.savedTarget.emit(this.targetUi());
          this.saved.emit();
          this.facade.refreshRecurring();
        },
        error: (e) => {
          this.toast.error(e?.message ?? 'Could not save recurring item');
        },
      });
  }
}
