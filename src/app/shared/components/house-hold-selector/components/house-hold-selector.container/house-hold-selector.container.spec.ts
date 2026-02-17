import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HouseHoldSelectorContainer } from './house-hold-selector.container';

describe('HouseHoldSelectorContainer', () => {
  let component: HouseHoldSelectorContainer;
  let fixture: ComponentFixture<HouseHoldSelectorContainer>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HouseHoldSelectorContainer]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HouseHoldSelectorContainer);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
