import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MembersAdmin } from './members-admin';

describe('MembersAdmin', () => {
  let component: MembersAdmin;
  let fixture: ComponentFixture<MembersAdmin>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MembersAdmin]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MembersAdmin);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
