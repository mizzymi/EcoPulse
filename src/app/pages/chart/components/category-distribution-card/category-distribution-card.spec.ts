import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CategoryDistributionCard } from './category-distribution-card';

describe('CategoryDistributionCard', () => {
  let component: CategoryDistributionCard;
  let fixture: ComponentFixture<CategoryDistributionCard>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CategoryDistributionCard]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CategoryDistributionCard);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
