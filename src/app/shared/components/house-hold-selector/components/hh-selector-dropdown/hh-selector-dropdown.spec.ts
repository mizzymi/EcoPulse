import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HhSelectorDropdown } from './hh-selector-dropdown';

describe('HhSelectorDropdown', () => {
  let component: HhSelectorDropdown;
  let fixture: ComponentFixture<HhSelectorDropdown>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HhSelectorDropdown]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HhSelectorDropdown);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
