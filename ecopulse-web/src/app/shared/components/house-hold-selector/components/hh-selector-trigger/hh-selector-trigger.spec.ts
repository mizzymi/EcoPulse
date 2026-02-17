import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HhSelectorTrigger } from './hh-selector-trigger';

describe('HhSelectorTrigger', () => {
  let component: HhSelectorTrigger;
  let fixture: ComponentFixture<HhSelectorTrigger>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HhSelectorTrigger]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HhSelectorTrigger);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
