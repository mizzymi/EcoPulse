import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SettingsTabs } from './settings-tabs';

describe('SettingsTabs', () => {
  let component: SettingsTabs;
  let fixture: ComponentFixture<SettingsTabs>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SettingsTabs]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SettingsTabs);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
