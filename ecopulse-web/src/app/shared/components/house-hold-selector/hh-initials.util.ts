export function toInitials(name: string): string {
    const parts = name.trim().split(/\s+/).filter(Boolean);
    const a = parts[0]?.[0] ?? 'M';
    const b = parts.length > 1 ? parts[1][0] : (parts[0]?.[1] ?? 'W');
    return (a + b).toUpperCase();
}
