import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PlannedPanel } from './planned-panel';

describe('PlannedPanel', () => {
  let component: PlannedPanel;
  let fixture: ComponentFixture<PlannedPanel>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PlannedPanel]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PlannedPanel);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
