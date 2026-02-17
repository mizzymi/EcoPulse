import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HhHouseholdList } from './hh-household-list';

describe('HhHouseholdList', () => {
  let component: HhHouseholdList;
  let fixture: ComponentFixture<HhHouseholdList>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HhHouseholdList]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HhHouseholdList);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
