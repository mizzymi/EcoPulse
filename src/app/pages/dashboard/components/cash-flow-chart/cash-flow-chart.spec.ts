import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CashFlowChart } from './cash-flow-chart';

describe('CashFlowChart', () => {
  let component: CashFlowChart;
  let fixture: ComponentFixture<CashFlowChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CashFlowChart]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CashFlowChart);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
