import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HistoryPagination } from './history-pagination';

describe('HistoryPagination', () => {
  let component: HistoryPagination;
  let fixture: ComponentFixture<HistoryPagination>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HistoryPagination]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HistoryPagination);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
