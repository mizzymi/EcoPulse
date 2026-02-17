import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AuthCardLogo } from './auth-card-logo';

describe('AuthCardLogo', () => {
  let component: AuthCardLogo;
  let fixture: ComponentFixture<AuthCardLogo>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AuthCardLogo]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AuthCardLogo);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
