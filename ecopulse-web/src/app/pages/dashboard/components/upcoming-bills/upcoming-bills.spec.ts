import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UpcomingBills } from './upcoming-bills';

describe('UpcomingBills', () => {
  let component: UpcomingBills;
  let fixture: ComponentFixture<UpcomingBills>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UpcomingBills]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UpcomingBills);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
