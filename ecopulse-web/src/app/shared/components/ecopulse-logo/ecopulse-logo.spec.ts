import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EcopulseLogo } from './ecopulse-logo';

describe('EcopulseLogo', () => {
  let component: EcopulseLogo;
  let fixture: ComponentFixture<EcopulseLogo>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [EcopulseLogo]
    })
    .compileComponents();

    fixture = TestBed.createComponent(EcopulseLogo);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
