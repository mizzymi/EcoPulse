import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HouseHoldSelector } from './house-hold-selector';

describe('HouseHoldSelector', () => {
  let component: HouseHoldSelector;
  let fixture: ComponentFixture<HouseHoldSelector>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HouseHoldSelector]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HouseHoldSelector);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
