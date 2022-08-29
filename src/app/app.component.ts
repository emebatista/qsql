import { Component } from '@angular/core';
import { PoMenuItem } from '@po-ui/ng-components';
import { ResultTableComponent } from './result-table/result-table.component';
@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {

  readonly menus: Array<PoMenuItem> = [
    { label: 'Sair', action: this.onClickSair.bind(this) }
  ];

  private onClickSair() {
    //@ts-ignore
    totvstec.jsToAdvpl('close', 'force');
  }

}

