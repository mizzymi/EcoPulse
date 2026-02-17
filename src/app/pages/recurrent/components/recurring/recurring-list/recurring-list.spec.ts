import { ComponentFixture, TestBed } from '@angular/core/testing';

import { RecurringList } from './recurring-list';

describe('RecurringList', () => {
  let component: RecurringList;
  let fixture: ComponentFixture<RecurringList>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RecurringList]
    })
    .compileComponents();

    fixture = TestBed.createComponent(RecurringList);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
