import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DonutChart } from './donut-chart';

describe('DonutChart', () => {
  let component: DonutChart;
  let fixture: ComponentFixture<DonutChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DonutChart]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DonutChart);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
