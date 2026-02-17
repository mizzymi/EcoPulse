import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SavingsFacade } from '../../data/savings.facade';
import { GoalForm } from '../goal-form/goal-form';
import { GoalsGrid } from '../goals-grid/goals-grid';

@Component({
  selector: 'app-savings-goals-shell',
  standalone: true,
  imports: [CommonModule, GoalsGrid, GoalForm],
  templateUrl: './savings-goals-shell.html',
})
export class SavingsGoalsShell {
  readonly facade = inject(SavingsFacade);
}
