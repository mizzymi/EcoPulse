import { ValidatorFn, AbstractControl, ValidationErrors } from "@angular/forms";

export const passwordsMatchValidator: ValidatorFn = (group: AbstractControl): ValidationErrors | null => {
    const pCtrl = group.get('password');
    const cCtrl = group.get('password2');
    if (!pCtrl || !cCtrl) return null;

    const normalize = (v: unknown) =>
        String(v ?? '')
            .normalize('NFKC')
            .replace(/[\u200B-\u200D\uFEFF]/g, '') // zero-width chars
            .replace(/\s+$/g, ''); // trailing spaces/newlines

    const p = normalize(pCtrl.value);
    const c = normalize(cCtrl.value);

    // If confirm empty, don't show mismatch yet
    if (!c) {
        if (cCtrl.errors?.['passwordsMismatch']) {
            const { passwordsMismatch, ...rest } = cCtrl.errors;
            cCtrl.setErrors(Object.keys(rest).length ? rest : null);
        }
        return null;
    }

    const mismatch = p !== c;

    // Set/clear on password2 without removing other errors
    const current = cCtrl.errors ?? {};
    if (mismatch) {
        if (!current['passwordsMismatch']) {
            cCtrl.setErrors({ ...current, passwordsMismatch: true });
        }
        return { passwordsMismatch: true };
    } else {
        if (current['passwordsMismatch']) {
            const { passwordsMismatch, ...rest } = current;
            cCtrl.setErrors(Object.keys(rest).length ? rest : null);
        }
        return null;
    }
};