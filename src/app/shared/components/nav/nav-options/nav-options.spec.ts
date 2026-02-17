import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NavOptions } from './nav-options';

describe('NavOptions', () => {
  let component: NavOptions;
  let fixture: ComponentFixture<NavOptions>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [NavOptions]
    })
    .compileComponents();

    fixture = TestBed.createComponent(NavOptions);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
