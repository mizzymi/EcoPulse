import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingIdEditForm } from './saving-id-edit-form';

describe('SavingIdEditForm', () => {
  let component: SavingIdEditForm;
  let fixture: ComponentFixture<SavingIdEditForm>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingIdEditForm]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingIdEditForm);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
