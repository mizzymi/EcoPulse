export interface OkResponseDto {
    ok: true;
}

export interface PostRecurringInstanceResponseDto {
    ok: true;
    postedId?: string;
    alreadyPosted?: boolean;
}