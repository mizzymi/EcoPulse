import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Recurrent } from './recurrent';

describe('Recurrent', () => {
  let component: Recurrent;
  let fixture: ComponentFixture<Recurrent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Recurrent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Recurrent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
