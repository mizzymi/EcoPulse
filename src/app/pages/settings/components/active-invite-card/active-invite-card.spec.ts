import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ActiveInviteCard } from './active-invite-card';

describe('ActiveInviteCard', () => {
  let component: ActiveInviteCard;
  let fixture: ComponentFixture<ActiveInviteCard>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ActiveInviteCard]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ActiveInviteCard);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
