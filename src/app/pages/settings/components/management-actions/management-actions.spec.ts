import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ManagementActions } from './management-actions';

describe('ManagementActions', () => {
  let component: ManagementActions;
  let fixture: ComponentFixture<ManagementActions>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ManagementActions]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ManagementActions);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
