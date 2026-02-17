import { Component } from '@angular/core';
import { BackgroundGadient, AuthHero } from "../../shared";
import { HomeAuthPanel, HomeMockPanel } from "./components";

@Component({
  selector: 'app-home',
  imports: [BackgroundGadient, AuthHero, HomeAuthPanel, HomeMockPanel],
  templateUrl: './home.html',
})
export class Home {

}
