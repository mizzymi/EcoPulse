import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ChartsHeader } from './charts-header';

describe('ChartsHeader', () => {
  let component: ChartsHeader;
  let fixture: ComponentFixture<ChartsHeader>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ChartsHeader]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ChartsHeader);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
