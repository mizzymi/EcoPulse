import { ComponentFixture, TestBed } from '@angular/core/testing';

import { RecurringPanel } from './recurring-panel';

describe('RecurringPanel', () => {
  let component: RecurringPanel;
  let fixture: ComponentFixture<RecurringPanel>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RecurringPanel]
    })
    .compileComponents();

    fixture = TestBed.createComponent(RecurringPanel);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
