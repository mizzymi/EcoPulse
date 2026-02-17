import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsideNavBar } from './aside-nav-bar';

describe('AsideNavBar', () => {
  let component: AsideNavBar;
  let fixture: ComponentFixture<AsideNavBar>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AsideNavBar]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AsideNavBar);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
