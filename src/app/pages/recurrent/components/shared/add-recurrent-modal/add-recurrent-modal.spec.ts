import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AddRecurrentModal } from './add-recurrent-modal';

describe('AddRecurrentModal', () => {
  let component: AddRecurrentModal;
  let fixture: ComponentFixture<AddRecurrentModal>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AddRecurrentModal]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AddRecurrentModal);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
