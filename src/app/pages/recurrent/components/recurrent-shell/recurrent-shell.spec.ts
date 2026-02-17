import { ComponentFixture, TestBed } from '@angular/core/testing';

import { RecurrentShell } from './recurrent-shell';

describe('RecurrentShell', () => {
  let component: RecurrentShell;
  let fixture: ComponentFixture<RecurrentShell>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RecurrentShell]
    })
    .compileComponents();

    fixture = TestBed.createComponent(RecurrentShell);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
