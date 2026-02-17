import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BackgroundGadient } from './background-gadient';

describe('BackgroundGadient', () => {
  let component: BackgroundGadient;
  let fixture: ComponentFixture<BackgroundGadient>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BackgroundGadient]
    })
    .compileComponents();

    fixture = TestBed.createComponent(BackgroundGadient);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
