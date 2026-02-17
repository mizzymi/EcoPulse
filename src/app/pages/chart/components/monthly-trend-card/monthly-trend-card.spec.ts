import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MonthlyTrendCard } from './monthly-trend-card';

describe('MonthlyTrendCard', () => {
  let component: MonthlyTrendCard;
  let fixture: ComponentFixture<MonthlyTrendCard>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MonthlyTrendCard]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MonthlyTrendCard);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
