import { inject } from '@angular/core';
import { CanActivateFn, CanMatchFn, Router, UrlTree } from '@angular/router';
import { ApiService } from '../../shared';

function checkGuest(): true | UrlTree {
    const api = inject(ApiService);
    const router = inject(Router);

    const token = api.getToken();

    if (token) {
        return router.createUrlTree(['/dashboard']);
    }

    return true;
}

export const guestGuard: CanActivateFn = () => checkGuest();
export const guestMatchGuard: CanMatchFn = () => checkGuest();
