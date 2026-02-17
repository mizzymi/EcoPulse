import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GoalForm } from './goal-form';

describe('GoalForm', () => {
  let component: GoalForm;
  let fixture: ComponentFixture<GoalForm>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [GoalForm]
    })
    .compileComponents();

    fixture = TestBed.createComponent(GoalForm);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
