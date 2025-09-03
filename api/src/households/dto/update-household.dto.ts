import { IsOptional, IsString, Length, MaxLength } from 'class-validator';

export class UpdateHouseholdDto {
  @IsOptional()
  @IsString()
  @MaxLength(64)
  name?: string;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;
}
