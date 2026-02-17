import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HouseHoldMembers } from './house-hold-members';

describe('HouseHoldMembers', () => {
  let component: HouseHoldMembers;
  let fixture: ComponentFixture<HouseHoldMembers>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HouseHoldMembers]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HouseHoldMembers);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
