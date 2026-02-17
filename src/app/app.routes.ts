import { Routes } from '@angular/router';
import { Chart, Dashboard, History, Home, Login, Recurrent, Register, SavingId, Savings } from './pages';
import { authMatchGuard, guestGuard } from './core';

export const routes: Routes = [

    { path: '', component: Home, canActivate: [guestGuard] },
    { path: 'auth/login', component: Login, canActivate: [guestGuard] },
    { path: 'auth/register', component: Register, canActivate: [guestGuard] },

    // Protected
    {
        path: '',
        canMatch: [authMatchGuard],
        children: [
            { path: 'dashboard', component: Dashboard },
            { path: 'history', component: History },
            { path: 'chart', component: Chart },
            { path: 'savings', component: Savings },
            { path: 'saving/:id', component: SavingId },
            { path: 'recurrent', component: Recurrent },
        ],
    },
];
