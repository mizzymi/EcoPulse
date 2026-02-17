import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HomeMockPanel } from './home-mock-panel';

describe('HomeMockPanel', () => {
  let component: HomeMockPanel;
  let fixture: ComponentFixture<HomeMockPanel>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HomeMockPanel]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HomeMockPanel);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
