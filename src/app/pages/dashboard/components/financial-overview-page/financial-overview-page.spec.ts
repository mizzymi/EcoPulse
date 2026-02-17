import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FinancialOverviewPage } from './financial-overview-page';

describe('FinancialOverviewPage', () => {
  let component: FinancialOverviewPage;
  let fixture: ComponentFixture<FinancialOverviewPage>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [FinancialOverviewPage]
    })
    .compileComponents();

    fixture = TestBed.createComponent(FinancialOverviewPage);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
