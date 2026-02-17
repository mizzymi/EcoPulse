import {
  Component,
} from '@angular/core';
import { HouseHoldSelectorContainer } from './components';

@Component({
  selector: 'app-house-hold-selector',
  standalone: true,
  imports: [HouseHoldSelectorContainer],
  templateUrl: './house-hold-selector.html',
})
export class HouseHoldSelector {
  
}
