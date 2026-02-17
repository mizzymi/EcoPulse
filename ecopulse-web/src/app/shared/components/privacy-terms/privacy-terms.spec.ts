import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PrivacyTerms } from './privacy-terms';

describe('PrivacyTerms', () => {
  let component: PrivacyTerms;
  let fixture: ComponentFixture<PrivacyTerms>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PrivacyTerms]
    })
    .compileComponents();

    fixture = TestBed.createComponent(PrivacyTerms);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
