import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NewEntryModal } from './new-entry-modal';

describe('NewEntryModal', () => {
  let component: NewEntryModal;
  let fixture: ComponentFixture<NewEntryModal>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [NewEntryModal]
    })
    .compileComponents();

    fixture = TestBed.createComponent(NewEntryModal);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
