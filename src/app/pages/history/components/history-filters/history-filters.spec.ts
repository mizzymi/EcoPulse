import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HistoryFilters } from './history-filters';

describe('HistoryFilters', () => {
  let component: HistoryFilters;
  let fixture: ComponentFixture<HistoryFilters>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HistoryFilters]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HistoryFilters);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
