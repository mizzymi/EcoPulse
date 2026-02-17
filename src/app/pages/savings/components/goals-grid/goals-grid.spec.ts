import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GoalsGrid } from './goals-grid';

describe('GoalsGrid', () => {
  let component: GoalsGrid;
  let fixture: ComponentFixture<GoalsGrid>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [GoalsGrid]
    })
    .compileComponents();

    fixture = TestBed.createComponent(GoalsGrid);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
