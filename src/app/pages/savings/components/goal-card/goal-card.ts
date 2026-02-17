import { Component, EventEmitter, Input, Output, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SavingsGoalDto } from '../../../../shared';
import { LucideAngularModule, Target } from 'lucide-angular';

@Component({
  selector: 'app-goal-card',
  standalone: true,
  imports: [CommonModule, LucideAngularModule],
  templateUrl: './goal-card.html',
})
export class GoalCard {
  @Input({ required: true }) goal!: SavingsGoalDto;
  @Output() delete = new EventEmitter<string>();
  public targetIcon = Target
  saved = computed(() => Number(this.goal.saved ?? 0));
  target = computed(() => Number(this.goal.target ?? 0));

  progressPct = computed(() => {
    const t = this.target();
    if (!t || t <= 0) return 0;
    const pct = (this.saved() / t) * 100;
    return Math.max(0, Math.min(100, Math.round(pct)));
  });

  deadlineLabel = computed(() => {
    if (!this.goal.deadline) return null;
    const d = new Date(this.goal.deadline);
    if (Number.isNaN(d.getTime())) return null;
    return d.toLocaleDateString();
  });
}
