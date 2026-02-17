import { inject } from '@angular/core';
import { CanActivateFn, CanMatchFn, Router, UrlTree } from '@angular/router';
import { ApiService } from '../../shared';

function checkAuth(): true | UrlTree {
    const api = inject(ApiService);
    const router = inject(Router);

    const token = api.getToken();

    if (!token) {
        return router.createUrlTree(['/auth/login']);
    }

    return true;
}

export const authGuard: CanActivateFn = () => checkAuth();
export const authMatchGuard: CanMatchFn = () => checkAuth();
