import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EcopulseNameLogo } from './ecopulse-name-logo';

describe('EcopulseNameLogo', () => {
  let component: EcopulseNameLogo;
  let fixture: ComponentFixture<EcopulseNameLogo>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [EcopulseNameLogo]
    })
    .compileComponents();

    fixture = TestBed.createComponent(EcopulseNameLogo);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
