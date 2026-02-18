import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, catchError, forkJoin, from, map, of, switchMap, tap, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Router } from '@angular/router';
import { encrypt } from './encrypt';

/* =========================================================
   Errors
   ========================================================= */

export type ApiErrorShape = {
    message?: string;
    error?: string;
    code?: string;
    statusCode?: number;
};

export class ApiError extends Error {
    status: number;
    code?: string;
    body?: unknown;

    constructor(message: string, status: number, code?: string, body?: unknown) {
        super(message);
        this.name = 'ApiError';
        this.status = status;
        this.code = code;
        this.body = body;
    }
}

/* =========================================================
   Request options
   ========================================================= */

export type RequestOptions = {
    /** If true, adds Authorization: Bearer <token> automatically */
    auth?: boolean;
    /** Override token (useful for special flows) */
    tokenOverride?: string;
    /** Extra headers */
    headers?: Record<string, string>;
    /** Query params */
    params?: Record<string, string | number | boolean | null | undefined>;
};

/* =========================================================
   Shared types (match your backend as close as possible)
   ========================================================= */

export type HouseholdRole = 'OWNER' | 'ADMIN' | 'MEMBER';
export type LedgerEntryType = 'INCOME' | 'EXPENSE';
export type SavingsTxnType = 'DEPOSIT' | 'WITHDRAW';

export type MoneyType = 'CASH' | 'BANK' | 'CARD' | 'OTHER';

export type PublicUserDto = {
    id: string;
    username: string;
    emailHash: string;
    createdAt?: string;
};

export type AuthResponseDto = {
    accessToken: string;
    user: PublicUserDto;
};

export type HouseholdListItemDto = {
    id: string;
    name: string;
    currency: string;
    role: HouseholdRole;
    joinedAt: string; // ISO
    memberCount: number;
};

export type HouseholdDto = {
    id: string;
    name: string;
    currency: string;
};

export type InviteCreateResponseDto = {
    code: string;
    expiresAt: string; // ISO
    maxUses: number;
    requireApproval: boolean;
};

export type JoinByCodeResponseDto = {
    status: 'APPROVED' | 'PENDING';
    householdId: string;
};

export type JoinRequestDto = {
    id: string;
    householdId: string;
    userId: string;
    inviteId: string;
    status: 'PENDING' | 'APPROVED' | 'REJECTED';
    createdAt: string; // ISO
    decidedAt: string | null;
    decidedBy: string | null;
    user: Pick<PublicUserDto, 'id' | 'emailHash' | 'username'>;
};

export type MembersListDto = {
    myRole: HouseholdRole;
    members: Array<{
        userId: string;
        role: HouseholdRole;
        joinedAt: string; // ISO
        user: Pick<PublicUserDto, 'id' | 'emailHash' | 'username'>;
        isMe: boolean;
    }>;
};

export type MemberRoleUpdateDto = {
    householdId: string;
    userId: string;
    role: HouseholdRole;
    joinedAt: string; // ISO
    user: Pick<PublicUserDto, 'id' | 'emailHash' | 'username'>;
};

export type LedgerEntryDto = {
    id: string;
    householdId: string;
    userId: string;
    type: LedgerEntryType;
    amount: number;
    category: string | null;
    note: string | null;
    occursAt: string; // ISO
    accountType: MoneyType;
    createdAt?: string; // if present
};

export type MonthlySummaryDto = {
    month: string; // YYYY-MM
    openingBalance: number;
    income: number;
    expense: number;
    net: number;
    closingBalance: number;
};

export type SavingsGoalDto = {
    id: string;
    householdId: string;
    name: string;
    target: number;
    deadline: string | null; // ISO
    createdBy: string;
    createdAt?: string;
    // computed fields from listSavingsGoals
    saved?: number;
    progress?: number;
};

export type SavingsTxnDto = {
    id: string;
    goalId: string;
    userId: string;
    type: SavingsTxnType;
    amount: number;
    note: string | null;
    occursAt: string; // ISO
    createdAt?: string;
};

export type SavingsGoalSummaryDto = {
    goal: SavingsGoalDto;
    saved: number;
    target: number;
    progress: number;
    remaining: number;
};

export type PlannedItemDto = {
    id: string;
    householdId: string;
    createdBy: string;
    concept: string;
    type: LedgerEntryType;
    amount: number;
    dueDate: string; // ISO
    month: string | null;
    notes: string | null;
    category: string | null;
    accountType: MoneyType;
    settledAt: string | null;
    createdAt?: string;
};

export type RecurringDefDto = {
    id: string;
    householdId: string;
    createdBy: string;
    active: boolean;
    concept: string;
    type: LedgerEntryType;
    amount: number;
    dayOfMonth: number | null;
    rrule: string | null;
    notes: string | null;
    category: string | null;
    accountType: MoneyType;
    createdAt?: string;
    /** When GET /recurring?month=YYYY-MM backend projects occursAt */
    occursAt?: string; // ISO
};

export type TransactionRow = {
    id: string;
    note: string;
    subtitle?: string;
    category?: string | null;
    categoryLabel?: string;
    date: string;
    paymentMethod?: string | null;
    paymentMethodLabel?: string;
    amount: number;
    currency: string;
    type?: 'INCOME' | 'EXPENSE';
};

export type PostRecurringInstanceResponseDto =
    | { ok: true; already: true; entry: LedgerEntryDto }
    | { ok: true; entry: LedgerEntryDto };

export type OkResponseDto = { ok: true };

/* =========================================================
   ApiService
   ========================================================= */

@Injectable({ providedIn: 'root' })
export class ApiService {
    private http = inject(HttpClient);
    private router = inject(Router);

    /** Backend base URL from environment */
    private readonly baseUrl = environment.backend;

    /** Local storage key for JWT */
    private readonly tokenKey = 'accessToken';

    // ----------------------------
    // Token helpers
    // ----------------------------

    getToken(): string | null {
        return localStorage.getItem(this.tokenKey);
    }

    setToken(token: string | null) {
        if (!token) localStorage.removeItem(this.tokenKey);
        else localStorage.setItem(this.tokenKey, token);
    }

    isLoggedIn(): boolean {
        return !!this.getToken();
    }

    // ----------------------------
    // Core request helpers
    // ----------------------------

    get<T>(path: string, opts: RequestOptions = {}): Observable<T> {
        return this.http.get<T>(this.url(path), this.makeOptions(opts)).pipe(catchError((e) => this.handleError(e)));
    }

    post<T>(path: string, body?: unknown, opts: RequestOptions = {}): Observable<T> {
        return this.http.post<T>(this.url(path), body ?? {}, this.makeOptions(opts)).pipe(catchError((e) => this.handleError(e)));
    }

    patch<T>(path: string, body?: unknown, opts: RequestOptions = {}): Observable<T> {
        return this.http.patch<T>(this.url(path), body ?? {}, this.makeOptions(opts)).pipe(catchError((e) => this.handleError(e)));
    }

    delete<T>(path: string, opts: RequestOptions = {}): Observable<T> {
        return this.http.delete<T>(this.url(path), this.makeOptions(opts)).pipe(catchError((e) => this.handleError(e)));
    }

    // =========================================================
    // AUTH ROUTES
    // =========================================================

    login(email: string, password: string) {
        const normalizedEmail = email.trim().toLowerCase();

        return from(Promise.all([encrypt(password), encrypt(normalizedEmail)])).pipe(
            switchMap(([passwordHash, emailHash]) =>
                this.post<AuthResponseDto>('/auth/login', { email: emailHash, password: passwordHash }, { auth: false })
            ),
            tap(res => this.setToken(res.accessToken)),
        );
    }

    register(email: string, password: string, username: string) {
        const normalizedEmail = email.trim().toLowerCase();
        const cleanUsername = username.trim();

        return from(Promise.all([encrypt(password), encrypt(normalizedEmail)])).pipe(
            switchMap(([passwordHash, emailHash]) =>
                this.post<AuthResponseDto>('/auth/register', { email: emailHash, username: cleanUsername, password: passwordHash }, { auth: false })
            ),
            tap(res => this.setToken(res.accessToken)),
        );
    }

    requestPasswordReset(email: string) {
        const normalized = email.trim().toLowerCase();
        return this.post<OkResponseDto>(
            "/auth/forgot-password",
            { email: normalized },
            { auth: false }
        );
    }

    resetPassword(email: string, token: string, newPassword: string): Observable<OkResponseDto> {
        const normalizedEmail = email.trim().toLowerCase();

        return from(Promise.all([encrypt(normalizedEmail), encrypt(newPassword)])).pipe(
            switchMap(([emailClientHash, passwordClientHash]) => {
                const dto = { email: emailClientHash, token, newPassword: passwordClientHash };
                return this.post<OkResponseDto>('/auth/reset-password', dto, { auth: false });
            }),
        );
    }

    logout(): void {
        this.setToken(null);
        this.router.navigate(['/auth/login']);
    }

    // =========================================================
    // HOUSEHOLDS ROUTES
    // Base: /households (jwtAuth)
    // =========================================================

    /** GET /households */
    myHouseholds(): Observable<HouseholdListItemDto[]> {
        return this.get<HouseholdListItemDto[]>('/households', { auth: true });
    }

    /** POST /households */
    createHousehold(name: string, currency: string = 'EUR'): Observable<HouseholdDto> {
        return this.post<HouseholdDto>('/households', { name, currency }, { auth: true });
    }

    /** DELETE /households/:id */
    deleteHousehold(householdId: string): Observable<OkResponseDto> {
        return this.delete<OkResponseDto>(`/households/${householdId}`, { auth: true });
    }

    /** PATCH /households/:id */
    updateHousehold(householdId: string, dto: { name?: string; currency?: string }): Observable<HouseholdDto> {
        return this.patch<HouseholdDto>(`/households/${householdId}`, dto, { auth: true });
    }

    // ----------------------------
    // Invites / Join
    // ----------------------------

    /** POST /households/:id/invites */
    createInvite(
        householdId: string,
        opts: { expiresInHours?: number; maxUses?: number; requireApproval?: boolean } = {},
    ): Observable<InviteCreateResponseDto> {
        return this.post<InviteCreateResponseDto>(`/households/${householdId}/invites`, opts, { auth: true });
    }

    /** POST /households/join */
    joinByCode(code: string): Observable<JoinByCodeResponseDto> {
        return this.post<JoinByCodeResponseDto>('/households/join', { code }, { auth: true });
    }

    /** POST /households/join-by-code (alias) */
    joinByCodeAlias(code: string): Observable<JoinByCodeResponseDto> {
        return this.post<JoinByCodeResponseDto>('/households/join-by-code', { code }, { auth: true });
    }

    // ----------------------------
    // Join requests
    // ----------------------------

    /** GET /households/:id/join-requests?status=PENDING|APPROVED|REJECTED */
    listJoinRequests(
        householdId: string,
        status: 'PENDING' | 'APPROVED' | 'REJECTED' = 'PENDING',
    ): Observable<JoinRequestDto[]> {
        return this.get<JoinRequestDto[]>(`/households/${householdId}/join-requests`, {
            auth: true,
            params: { status },
        });
    }

    /** POST /households/:id/join-requests/:reqId/approve */
    approveJoinRequest(householdId: string, reqId: string): Observable<{ ok: true; status: 'APPROVED' }> {
        return this.post<{ ok: true; status: 'APPROVED' }>(
            `/households/${householdId}/join-requests/${reqId}/approve`,
            {},
            { auth: true },
        );
    }

    /** POST /households/:id/join-requests/:reqId/reject */
    rejectJoinRequest(householdId: string, reqId: string): Observable<{ ok: true; status: 'REJECTED' }> {
        return this.post<{ ok: true; status: 'REJECTED' }>(
            `/households/${householdId}/join-requests/${reqId}/reject`,
            {},
            { auth: true },
        );
    }

    // ----------------------------
    // Members
    // ----------------------------

    /** GET /households/:id/members */
    listMembers(householdId: string): Observable<MembersListDto> {
        return this.get<MembersListDto>(`/households/${householdId}/members`, { auth: true });
    }

    /** PATCH /households/:id/members/:userId  { role } */
    updateMemberRole(
        householdId: string,
        userId: string,
        dto: { role?: 'ADMIN' | 'MEMBER' },
    ): Observable<MemberRoleUpdateDto> {
        return this.patch<MemberRoleUpdateDto>(`/households/${householdId}/members/${userId}`, dto, { auth: true });
    }

    /** DELETE /households/:id/members/:userId */
    removeMember(householdId: string, userId: string): Observable<OkResponseDto> {
        return this.delete<OkResponseDto>(`/households/${householdId}/members/${userId}`, { auth: true });
    }

    // =========================================================
    // LEDGER ROUTES
    // =========================================================

    /** POST /households/:id/entries */
    addEntry(
        householdId: string,
        dto: {
            type: LedgerEntryType;
            amount: number | string;
            category?: string;
            note?: string;
            occursAt?: string | Date;
            accountType?: unknown;
        },
    ): Observable<LedgerEntryDto> {
        return this.post<LedgerEntryDto>(`/households/${householdId}/entries`, dto, { auth: true });
    }

    /** GET /households/:id/entries */
    listEntries(
        householdId: string,
        q: { from?: string; to?: string; limit?: number; accountType?: string; category?: string; type?: string } = {},
    ): Observable<LedgerEntryDto[]> {
        return this.get<LedgerEntryDto[]>(`/households/${householdId}/entries`, {
            auth: true,
            params: q as any,
        });
    }

    /** PATCH /households/:id/entries/:entryId */
    updateEntry(
        householdId: string,
        entryId: string,
        dto: {
            type?: LedgerEntryType;
            amount?: number | string;
            category?: string | null;
            note?: string | null;
            occursAt?: string | Date;
            accountType?: unknown;
        },
    ): Observable<LedgerEntryDto> {
        return this.patch<LedgerEntryDto>(`/households/${householdId}/entries/${entryId}`, dto, { auth: true });
    }

    /** DELETE /households/:id/entries/:entryId */
    deleteEntry(householdId: string, entryId: string): Observable<OkResponseDto> {
        return this.delete<OkResponseDto>(`/households/${householdId}/entries/${entryId}`, { auth: true });
    }

    /** GET /households/:id/summary?month=YYYY-MM */
    monthlySummary(householdId: string, month: string): Observable<MonthlySummaryDto> {
        return this.get<MonthlySummaryDto>(`/households/${householdId}/summary`, {
            auth: true,
            params: { month },
        });
    }

    // =========================================================
    // SAVINGS ROUTES
    // =========================================================

    /** POST /households/:id/savings-goals */
    createSavingsGoal(
        householdId: string,
        dto: { name: string; target: number | string; deadline?: string | Date },
    ): Observable<SavingsGoalDto> {
        return this.post<SavingsGoalDto>(`/households/${householdId}/savings-goals`, dto, { auth: true });
    }

    /** GET /households/:id/savings-goals */
    listSavingsGoals(householdId: string): Observable<SavingsGoalDto[]> {
        return this.get<SavingsGoalDto[]>(`/households/${householdId}/savings-goals`, { auth: true }).pipe(
            map((rows) =>
                rows.map((g) => ({
                    ...g,
                    target: typeof (g as any).target === 'string' ? Number((g as any).target) : g.target,
                })),
            ),
        );
    }

    /** PATCH /households/:id/savings-goals/:goalId */
    updateSavingsGoal(
        householdId: string,
        goalId: string,
        dto: { name?: string; target?: number | string; deadline?: string | Date | null },
    ): Observable<SavingsGoalDto> {
        return this.patch<SavingsGoalDto>(`/households/${householdId}/savings-goals/${goalId}`, dto, { auth: true });
    }

    /** DELETE /households/:id/savings-goals/:goalId */
    deleteSavingsGoal(householdId: string, goalId: string): Observable<OkResponseDto> {
        return this.delete<OkResponseDto>(`/households/${householdId}/savings-goals/${goalId}`, { auth: true });
    }

    /** POST /households/:id/savings-goals/:goalId/txns */
    addSavingsTxn(
        householdId: string,
        goalId: string,
        dto: { type: SavingsTxnType; amount: number | string; note?: string; occursAt?: string | Date },
    ): Observable<SavingsTxnDto> {
        return this.post<SavingsTxnDto>(`/households/${householdId}/savings-goals/${goalId}/txns`, dto, { auth: true });
    }

    /** GET /households/:id/savings-goals/:goalId/txns */
    listSavingsTxns(householdId: string, goalId: string): Observable<SavingsTxnDto[]> {
        return this.get<SavingsTxnDto[]>(`/households/${householdId}/savings-goals/${goalId}/txns`, { auth: true });
    }

    /** GET /households/:id/savings-goals/:goalId/summary */
    savingsGoalSummary(householdId: string, goalId: string): Observable<SavingsGoalSummaryDto> {
        return this.get<SavingsGoalSummaryDto>(`/households/${householdId}/savings-goals/${goalId}/summary`, {
            auth: true,
        });
    }

    /** DELETE /households/:id/savings-goals/:goalId/txns/:txnId */
    deleteSavingsTxn(householdId: string, goalId: string, txnId: string) {
        return this.delete<{ ok: true }>(
            `/households/${householdId}/savings-goals/${goalId}/txns/${txnId}`,
            { auth: true },
        );
    }

    /** GET /households/savings-goals/:goalId */
    getSavingsGoalById(goalId: string): Observable<SavingsGoalDto> {
        return this.get<SavingsGoalDto>(`/households/savings-goals/${goalId}`, { auth: true });
    }

    // =========================================================
    // PLANNED ROUTES
    // =========================================================

    /** GET /households/:id/planned?month=YYYY-MM&accountType=&category=&type= */
    listPlanned(
        householdId: string,
        q: { month?: string; accountType?: string; category?: string; type?: string } = {},
    ): Observable<PlannedItemDto[]> {
        return this.get<PlannedItemDto[]>(`/households/${householdId}/planned`, {
            auth: true,
            params: q as any,
        });
    }

    /** POST /households/:id/planned */
    createPlanned(
        householdId: string,
        dto: {
            concept: string;
            amount: number | string;
            type: LedgerEntryType;
            dueDate: string;
            month?: string;
            notes?: string;
            category?: string;
            accountType?: unknown;
        },
    ): Observable<PlannedItemDto> {
        return this.post<PlannedItemDto>(`/households/${householdId}/planned`, dto, { auth: true });
    }

    /** PATCH /households/:id/planned/:plannedId */
    updatePlanned(
        householdId: string,
        plannedId: string,
        dto: {
            concept?: string;
            amount?: number | string;
            type?: LedgerEntryType;
            dueDate?: string;
            month?: string | null;
            notes?: string | null;
            category?: string | null;
            accountType?: unknown;
        },
    ): Observable<PlannedItemDto> {
        return this.patch<PlannedItemDto>(`/households/${householdId}/planned/${plannedId}`, dto, { auth: true });
    }

    /** DELETE /households/:id/planned/:plannedId */
    deletePlanned(householdId: string, plannedId: string): Observable<OkResponseDto> {
        return this.delete<OkResponseDto>(`/households/${householdId}/planned/${plannedId}`, { auth: true });
    }

    /** POST /households/:id/planned/:plannedId/settle */
    settlePlanned(householdId: string, plannedId: string): Observable<{ ok: true } | { ok: true; alreadySettled: true }> {
        return this.post<{ ok: true } | { ok: true; alreadySettled: true }>(
            `/households/${householdId}/planned/${plannedId}/settle`,
            {},
            { auth: true },
        );
    }

    // =========================================================
    // RECURRING ROUTES
    // =========================================================

    /** GET /households/:id/recurring?month=YYYY-MM&accountType=&category=&type= */
    listRecurring(
        householdId: string,
        q: { month?: string; accountType?: string; category?: string; type?: string } = {},
    ): Observable<RecurringDefDto[]> {
        return this.get<RecurringDefDto[]>(`/households/${householdId}/recurring`, {
            auth: true,
            params: q as any,
        }).pipe(
            map((rows) =>
                rows.map((r) => ({
                    ...r,
                    amount: typeof (r as any).amount === 'string' ? Number((r as any).amount) : r.amount,
                })),
            ),
        );
    }

    /** POST /households/:id/recurring */
    createRecurring(
        householdId: string,
        dto: {
            concept: string;
            amount: number | string;
            type: LedgerEntryType;
            dayOfMonth?: number;
            rrule?: string;
            notes?: string;
            category?: string;
            accountType?: unknown;
        },
    ): Observable<RecurringDefDto> {
        return this.post<RecurringDefDto>(`/households/${householdId}/recurring`, dto, { auth: true });
    }

    /** PATCH /households/:id/recurring/:recurringId */
    updateRecurring(
        householdId: string,
        recurringId: string,
        dto: {
            concept?: string;
            amount?: number | string;
            type?: LedgerEntryType;
            dayOfMonth?: number | null;
            rrule?: string | null;
            notes?: string | null;
            category?: string | null;
            accountType?: unknown;
        },
    ): Observable<RecurringDefDto> {
        return this.patch<RecurringDefDto>(`/households/${householdId}/recurring/${recurringId}`, dto, { auth: true });
    }

    /** DELETE /households/:id/recurring/:recurringId */
    deleteRecurring(householdId: string, recurringId: string): Observable<OkResponseDto> {
        return this.delete<OkResponseDto>(`/households/${householdId}/recurring/${recurringId}`, { auth: true });
    }

    /** POST /households/:id/recurring/:recurringId/post */
    postRecurringInstance(
        householdId: string,
        recurringId: string,
        dto?: { month?: string; occursAt?: string | Date },
    ): Observable<PostRecurringInstanceResponseDto> {
        return this.post<PostRecurringInstanceResponseDto>(
            `/households/${householdId}/recurring/${recurringId}/post`,
            dto ?? {},
            { auth: true },
        );
    }

    // =========================================================
    // Internals
    // =========================================================

    private url(path: string) {
        const p = path.startsWith('/') ? path : `/${path}`;
        const base = this.baseUrl.replace(/\/+$/, '');
        return `${base}${p}`;
    }

    private makeOptions(opts: RequestOptions) {
        let headers = new HttpHeaders({
            'Content-Type': 'application/json',
            ...(opts.headers ?? {}),
        });

        if (opts.auth) {
            const token = opts.tokenOverride ?? this.getToken();
            if (token) headers = headers.set('Authorization', `Bearer ${token}`);
        }

        let params = new HttpParams();
        if (opts.params) {
            for (const [k, v] of Object.entries(opts.params)) {
                if (v === undefined || v === null) continue;
                params = params.set(k, String(v));
            }
        }

        return { headers, params };
    }

    private handleError(err: unknown) {
        if (err instanceof HttpErrorResponse) {
            const status = err.status;
            const body = err.error as any;

            const message =
                typeof body === 'string'
                    ? body
                    : body?.message || body?.error || `HTTP ${status} ${err.statusText}`;

            const code = typeof body === 'string' ? undefined : body?.code;

            return throwError(() => new ApiError(message, status, code, body));
        }

        return throwError(() => new ApiError('Unexpected error', 0));
    }

    /**
 * Auto-post recurring items that are due today.
 * Safe because backend postRecurringInstance is idempotent (returns already:true).
 */
    autoPostRecurringToday(householdId: string) {
        const now = new Date();
        const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

        // create a canonical occursAt at noon UTC for today (same as backend)
        const occursAt = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 12, 0, 0, 0)).toISOString();

        return this.listRecurring(householdId, { month }).pipe(
            map(rows => (rows ?? []).filter(r => r.active !== false)),
            map(rows => rows.filter(r => isDueToday(r, now))), // handles dayOfMonth and projected occursAt
            switchMap(due => {
                if (due.length === 0) return of({ posted: 0, already: 0 });

                return forkJoin(
                    due.map(r =>
                        this.postRecurringInstance(householdId, r.id, { month, occursAt }).pipe(
                            catchError(() => of(null))
                        )
                    )
                ).pipe(
                    map(results => {
                        let posted = 0;
                        let already = 0;
                        for (const res of results) {
                            if (!res) continue;
                            if ((res as any).already) already++;
                            else posted++;
                        }
                        return { posted, already };
                    })
                );
            })
        );
    }
}

function isDueToday(r: any, today: Date) {
    if (r.occursAt) {
        const d = new Date(r.occursAt);
        return d.getUTCFullYear() === today.getUTCFullYear()
            && d.getUTCMonth() === today.getUTCMonth()
            && d.getUTCDate() === today.getUTCDate();
    }

    if (typeof r.dayOfMonth === 'number') {
        return r.dayOfMonth === today.getDate();
    }

    return false;
}
