import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SavingIdHeader } from './saving-id-header';

describe('SavingIdHeader', () => {
  let component: SavingIdHeader;
  let fixture: ComponentFixture<SavingIdHeader>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SavingIdHeader]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SavingIdHeader);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
