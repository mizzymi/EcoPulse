import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HomeAuthPanel } from './home-auth-panel';

describe('HomeAuthPanel', () => {
  let component: HomeAuthPanel;
  let fixture: ComponentFixture<HomeAuthPanel>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HomeAuthPanel]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HomeAuthPanel);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
