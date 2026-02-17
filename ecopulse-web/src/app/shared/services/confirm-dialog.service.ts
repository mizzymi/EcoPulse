import { Injectable, signal } from '@angular/core';

export type ConfirmDialogTone = 'danger' | 'neutral';

export type ConfirmDialogOptions = {
    title?: string;
    message?: string;
    cancelText?: string;
    confirmText?: string;
    tone?: ConfirmDialogTone;
};

type ConfirmDialogState = Required<ConfirmDialogOptions> & { open: boolean };

@Injectable({ providedIn: 'root' })
export class ConfirmDialogService {
    // UI state (signals so templates react instantly)
    readonly state = signal<ConfirmDialogState>({
        open: false,
        title: 'Confirm',
        message: 'Are you sure?',
        cancelText: 'Cancel',
        confirmText: 'Confirm',
        tone: 'neutral',
    });

    // Promise resolver for the current confirmation
    private resolver: ((value: boolean) => void) | null = null;

    /**
     * Opens the confirmation modal and resolves to true/false.
     * This is safe to call from anywhere (History, other screens...).
     */
    confirm(options: ConfirmDialogOptions): Promise<boolean> {
        // If a confirm is already open, auto-cancel it (avoids dangling promises)
        if (this.resolver) {
            this.resolver(false);
            this.resolver = null;
        }

        this.state.update(s => ({
            ...s,
            open: true,
            title: options.title ?? s.title,
            message: options.message ?? s.message,
            cancelText: options.cancelText ?? s.cancelText,
            confirmText: options.confirmText ?? s.confirmText,
            tone: options.tone ?? s.tone,
        }));

        return new Promise<boolean>(resolve => {
            this.resolver = resolve;
        });
    }

    /** User clicked cancel/backdrop/close */
    cancel(): void {
        this.finish(false);
    }

    /** User clicked confirm */
    accept(): void {
        this.finish(true);
    }

    private finish(result: boolean): void {
        this.state.update(s => ({ ...s, open: false }));
        if (this.resolver) {
            this.resolver(result);
            this.resolver = null;
        }
    }
}
