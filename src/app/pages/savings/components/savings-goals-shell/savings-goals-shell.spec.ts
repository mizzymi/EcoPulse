import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingsGoalsShell } from './savings-goals-shell';

describe('SavingsGoalsShell', () => {
  let component: SavingsGoalsShell;
  let fixture: ComponentFixture<SavingsGoalsShell>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingsGoalsShell]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingsGoalsShell);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
