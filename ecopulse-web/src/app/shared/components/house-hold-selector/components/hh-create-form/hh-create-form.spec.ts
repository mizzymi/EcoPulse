import { ComponentFixture, TestBed } from '@angular/core/testing';

import { HhCreateForm } from './hh-create-form';

describe('HhCreateForm', () => {
  let component: HhCreateForm;
  let fixture: ComponentFixture<HhCreateForm>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HhCreateForm]
    })
    .compileComponents();

    fixture = TestBed.createComponent(HhCreateForm);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
