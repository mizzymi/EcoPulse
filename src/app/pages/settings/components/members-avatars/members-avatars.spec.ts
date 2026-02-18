import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MembersAvatars } from './members-avatars';

describe('MembersAvatars', () => {
  let component: MembersAvatars;
  let fixture: ComponentFixture<MembersAvatars>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MembersAvatars]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MembersAvatars);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
