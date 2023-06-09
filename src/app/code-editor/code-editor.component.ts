import { Component, OnInit } from '@angular/core';
import { gravaLog } from '../historico-comandos/historico-comandos.component';
import { SharedService } from '../shared.service/shared-service.service';
import { PoTableColumn } from '@po-ui/ng-components';
import { environment } from 'src/environments/environment';
import { PoNotificationService } from '@po-ui/ng-components';

@Component({
  selector: 'app-code-editor',
  templateUrl: './code-editor.component.html',
  styleUrls: ['./code-editor.component.css']
})

export class CodeEditorComponent implements OnInit {
  codeEditor: string;
  url: string;
  usuario: string;
  senha: string;
  event!: string;
  ERP: boolean;

  constructor(public poNotificar: PoNotificationService, private sharedService: SharedService) {
    this.codeEditor = ' ';
    this.url = '';
    this.usuario = '';
    this.senha = '';
    this.poNotificar.setDefaultDuration(3000);
    this.ERP = sessionStorage.getItem("ProCompany") == null ? false : true;
  }

  busca_dados() {
    let URL = '/app-root';
    let text_token = '';
    let login_txt = ' ';
    let empresa = '';
    let filial = '';
    
    const sharedService = this.sharedService;
    const notificar = this.poNotificar;

  
    if (this.codeEditor == ' ') {
      gravaLog('Script Vazio ');
      notificar.error('Script Vazio');
    }

    /* componentes html */
    const tabela = document.getElementById('tabela') as HTMLTableElement | null;
    const log_table = document.getElementById('historico-comandos') as HTMLTableElement | null;

    if (log_table) {
      log_table.innerHTML = ' ';
    }

    /* constantes do ERP */
    if (this.ERP) {
      empresa = JSON.parse(sessionStorage.getItem("ProCompany")!)['Code']; //JSON.parse(sessionStorage.getItem("ProCompany")!);
      filial = JSON.parse(sessionStorage.getItem("ProBranch")!)['Code']; //JSON.parse(sessionStorage.getItem("ProBranch")!);
      URL = window.location['origin'] + '/app-root';
      text_token = JSON.parse(sessionStorage.getItem("ERPTOKEN")!)['access_token'];
    }
    else {

      if (environment.production) {
        URL = this.url;
      } else {
        URL = '/app-root';
      };
      gravaLog('url origem: ' + URL);

      login_txt = window.btoa(this.usuario + ':' + this.senha);
    }

    if (tabela) {
      tabela.innerHTML = ''
    };

    const request = new XMLHttpRequest();

    request.open('GET', URL + '/qsql' + "?Query=" + this.codeEditor, true)

    request.timeout = 30000 * 20;

    if (this.ERP) {
      gravaLog('Origem: ERP');
      request.setRequestHeader('Authorization', 'Bearer ' + text_token);
    } else {
      gravaLog('Origem: browser ');
      request.setRequestHeader('Authorization', 'Basic ' + login_txt);
    }

    request.onerror = function (erro) {
      gravaLog('Erro ' + erro)
      notificar.error('Erro: ' + erro);
    };

    request.onload = () => {
      gravaLog('Final da carga ')
    };

    request.ontimeout = (e) => {
      gravaLog(request.readyState + '|' + request.status + '|' + 'Timeout 30 segundos ')
    };

    request.onreadystatechange = function () {

      if (request.readyState === 4 && request.status === 200) {
        let dados = JSON.parse(request.responseText);
        let tabela_dados = dados.objects;
        // let lista_de_campos = Object.keys(tabela_dados[0]);

        const listaCamposAux = Object.entries(dados.labels)[0][1] as { [key: string]: string };
        const lista_colunas = Object.entries(listaCamposAux).map(([property, label]) => ({
          property: property,
          label: label.trim() + ' (' + property + ')'
        }));

        // const table = document.getElementById('table')

        // const row = tabela?.insertRow();
        gravaLog('Obtendo dados... ')
        sharedService.setSharedVariable([<PoTableColumn>lista_colunas, dados.objects]);
        notificar.success('Conectado');
      }
      else {
        switch (request.readyState) {
          case 0:
            gravaLog('Unsent...');
            break;
          case 1:
            gravaLog('Opened...');
            break;
          case 2:
            gravaLog('Headers received...');
            break;
          case 3:
            gravaLog('Loading...');
            break;
          case 4:
            gravaLog('Done... ' + request.statusText);
            notificar.error(request.statusText);
            break;
          default:
            gravaLog(request.readyState + '|' + request.status + '|' + 'url:' + URL + 'status:' + request.status + ' ' + request.statusText + request.responseText);
            break;
        }
      }
    }
    request.send();
  };

  ngOnInit() {
    this.restore();
  }

  restore() {
    this.codeEditor = 'SELECT * FROM SF5010 ';
  }

  getColumns(columnsData: any[]): Array<PoTableColumn> {
    return columnsData.map(column => ({
      property: column.property,
      label: column.label
    }));
  }

  getItems(itemsData: any[]): any[] {
    return itemsData;
  }

}

