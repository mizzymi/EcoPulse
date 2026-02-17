import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SavingsFacade } from '../../data/savings.facade';
import { GoalCard } from '../goal-card/goal-card';
import { SavingsGoalDto } from '../../../../shared';

@Component({
  selector: 'app-goals-grid',
  standalone: true,
  imports: [CommonModule, GoalCard],
  templateUrl: './goals-grid.html',
})
export class GoalsGrid {
  readonly facade = inject(SavingsFacade);
  trackById = (_: number, g: SavingsGoalDto) => g.id;
}
