import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BottomNavBar } from './bottom-nav-bar';

describe('BottomNavBar', () => {
  let component: BottomNavBar;
  let fixture: ComponentFixture<BottomNavBar>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BottomNavBar]
    })
    .compileComponents();

    fixture = TestBed.createComponent(BottomNavBar);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
