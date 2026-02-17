import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HhHouseholdRow } from './hh-household-row';

describe('HhHouseholdRow', () => {
  let component: HhHouseholdRow;
  let fixture: ComponentFixture<HhHouseholdRow>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HhHouseholdRow]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HhHouseholdRow);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
