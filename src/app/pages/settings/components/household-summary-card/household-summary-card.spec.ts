import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HouseholdSummaryCard } from './household-summary-card';

describe('HouseholdSummaryCard', () => {
  let component: HouseholdSummaryCard;
  let fixture: ComponentFixture<HouseholdSummaryCard>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HouseholdSummaryCard]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HouseholdSummaryCard);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
