import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingIdSummary } from './saving-id-summary';

describe('SavingIdSummary', () => {
  let component: SavingIdSummary;
  let fixture: ComponentFixture<SavingIdSummary>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingIdSummary]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingIdSummary);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
