import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HistoryHeader } from './history-header';

describe('HistoryHeader', () => {
  let component: HistoryHeader;
  let fixture: ComponentFixture<HistoryHeader>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HistoryHeader]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HistoryHeader);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
