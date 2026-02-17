import { Injectable, computed, inject, signal } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { catchError, map, Observable, of, switchMap, throwError } from 'rxjs';
import { ApiService, OkResponseDto, SavingsGoalDto } from '../../../shared/services/api.service';

type LoadState<T> = {
    loading: boolean;
    error: string | null;
    data: T;
};

@Injectable({ providedIn: 'root' })
export class SavingsFacade {
    private api = inject(ApiService);

    readonly householdId = signal<string | null>(null);

    private readonly _refreshTick = signal(0);
    readonly refresh = () => this._refreshTick.update((n) => n + 1);

    private readonly MSG_NO_HOUSEHOLD =
        $localize`:Savings|Error when no household is selected@@savings.err.noHousehold:No household selected`;
    private readonly MSG_LOAD_GOALS_FAILED =
        $localize`:Savings|Error when loading savings goals@@savings.err.loadGoalsFailed:Failed to load savings goals`;

    private readonly _trigger$ = toObservable(
        computed(() => ({
            householdId: this.householdId(),
            tick: this._refreshTick(),
        })),
    );

    private readonly _goalsState = toSignal(
        this._trigger$.pipe(
            switchMap(({ householdId }) => {
                if (!householdId) {
                    return of<LoadState<SavingsGoalDto[]>>({
                        loading: false,
                        error: null,
                        data: [],
                    });
                }

                return this.api.listSavingsGoals(householdId).pipe(
                    map((rows) => ({
                        loading: false,
                        error: null,
                        data: rows ?? [],
                    })),
                    catchError((e: any) =>
                        of<LoadState<SavingsGoalDto[]>>({
                            loading: false,
                            error:
                                typeof e?.message === 'string' && e.message.trim()
                                    ? e.message
                                    : this.MSG_LOAD_GOALS_FAILED,
                            data: [],
                        }),
                    ),
                );
            }),
        ),
        { initialValue: { loading: true, error: null, data: [] } as LoadState<SavingsGoalDto[]> },
    );

    readonly goalsLoading = computed(() => this._goalsState().loading);
    readonly goalsError = computed(() => this._goalsState().error);
    readonly goals = computed(() => this._goalsState().data);

    readonly goalsSorted = computed(() => {
        const rows = [...this.goals()];
        rows.sort((a, b) => {
            const da = a.deadline ? new Date(a.deadline).getTime() : Number.POSITIVE_INFINITY;
            const db = b.deadline ? new Date(b.deadline).getTime() : Number.POSITIVE_INFINITY;
            return da - db;
        });
        return rows;
    });

    createGoal(dto: { name: string; target: number; deadline?: string | Date }): Observable<SavingsGoalDto> {
        const householdId = this.householdId();
        if (!householdId) return throwError(() => new Error(this.MSG_NO_HOUSEHOLD));

        return this.api.createSavingsGoal(householdId, dto).pipe(
            map((res) => {
                this.refresh();
                return res;
            }),
        );
    }

    deleteGoal(goalId: string): Observable<OkResponseDto> {
        const householdId = this.householdId();
        if (!householdId) return throwError(() => new Error(this.MSG_NO_HOUSEHOLD));

        return this.api.deleteSavingsGoal(householdId, goalId).pipe(
            map((res) => {
                this.refresh();
                return res;
            }),
        );
    }

    updateGoal(
        goalId: string,
        dto: { name?: string; target?: number; deadline?: string | Date | null },
    ): Observable<SavingsGoalDto> {
        const householdId = this.householdId();
        if (!householdId) return throwError(() => new Error(this.MSG_NO_HOUSEHOLD));

        return this.api.updateSavingsGoal(householdId, goalId, dto).pipe(
            map((res) => {
                this.refresh();
                return res;
            }),
        );
    }
}
