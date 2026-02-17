import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingIdTxnsList } from './saving-id-txns-list';

describe('SavingIdTxnsList', () => {
  let component: SavingIdTxnsList;
  let fixture: ComponentFixture<SavingIdTxnsList>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingIdTxnsList]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingIdTxnsList);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
