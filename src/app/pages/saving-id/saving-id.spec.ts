import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingId } from './saving-id';

describe('SavingId', () => {
  let component: SavingId;
  let fixture: ComponentFixture<SavingId>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingId]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingId);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
