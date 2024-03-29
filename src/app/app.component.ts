import { Component } from '@angular/core';
import { PoMenuItem } from '@po-ui/ng-components';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {

  readonly menus: Array<PoMenuItem> = [
    { label: ' ', action: this.onClickSair.bind(this) }
  ];

  private onClickSair() {
    //@ts-ignore
    totvstec.jsToAdvpl('close', 'force');
  }

}

