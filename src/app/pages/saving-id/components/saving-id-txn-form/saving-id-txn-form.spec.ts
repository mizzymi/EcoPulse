import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingIdTxnForm } from './saving-id-txn-form';

describe('SavingIdTxnForm', () => {
  let component: SavingIdTxnForm;
  let fixture: ComponentFixture<SavingIdTxnForm>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingIdTxnForm]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingIdTxnForm);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
