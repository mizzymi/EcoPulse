import { Component } from '@angular/core';
import { BackgroundGadient, AuthHero, LangSwitcher } from "../../shared";
import { HomeAuthPanel, HomeMockPanel } from "./components";

@Component({
  selector: 'app-home',
  imports: [BackgroundGadient, AuthHero, HomeAuthPanel, HomeMockPanel, LangSwitcher],
  templateUrl: './home.html',
})
export class Home {

}
