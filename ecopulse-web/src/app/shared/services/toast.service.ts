import { Injectable, signal } from '@angular/core';

export type ToastType = 'success' | 'error';

export interface ToastState {
    open: boolean;
    type: ToastType;
    message: string;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
    private timer: any;

    state = signal<ToastState>({
        open: false,
        type: 'success',
        message: '',
    });

    success(message: string, ms = 2500) {
        this.show('success', message, ms);
    }

    error(message: string, ms = 3500) {
        this.show('error', message, ms);
    }

    hide() {
        clearTimeout(this.timer);
        this.state.update((s) => ({ ...s, open: false }));
    }

    private show(type: ToastType, message: string, ms: number) {
        clearTimeout(this.timer);
        this.state.set({ open: true, type, message });

        this.timer = setTimeout(() => {
            this.state.update((s) => ({ ...s, open: false }));
        }, ms);
    }
}
