import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PlannedList } from './planned-list';

describe('PlannedList', () => {
  let component: PlannedList;
  let fixture: ComponentFixture<PlannedList>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PlannedList]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PlannedList);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
