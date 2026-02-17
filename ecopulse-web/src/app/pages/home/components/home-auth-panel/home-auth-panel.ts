import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { EcopulseNameLogo, PrivacyTerms } from '../../../../shared';

@Component({
  selector: 'app-home-auth-panel',
  standalone: true,
  imports: [RouterLink, EcopulseNameLogo, PrivacyTerms],
  templateUrl: './home-auth-panel.html',
})
export class HomeAuthPanel { }
