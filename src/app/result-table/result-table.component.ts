import { Component, OnInit, Injectable } from '@angular/core';
import { SharedService } from '../shared.service/shared-service.service';

@Component({
  selector: 'app-result-table',
  templateUrl: './result-table.component.html',
  styleUrls: ['./result-table.component.css']
})

@Injectable()
export class ResultTableComponent {
  localVariable: any;
  items = [];
  columns = [];

  constructor(private sharedService: SharedService) {
  }

  ngOnInit() {
    this.sharedService.getSharedVariable().subscribe(value => {
      this.localVariable = value;
      this.columns = value[0];
      this.items = value[1];
      // Outras ações a serem realizadas quando a variável compartilhada for atualizada
    });
    // Inicialize a propriedade local com o valor atual da variável compartilhada
    this.localVariable = this.sharedService.sharedVariable;
  }

}

