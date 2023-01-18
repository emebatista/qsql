import { Component, OnInit } from '@angular/core';
import { gravaLog } from '../historico-comandos/historico-comandos.component';

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

  constructor() {
    this.codeEditor = ' ';
    this.url = '';
    this.usuario = '';
    this.senha = '';
    this.ERP = sessionStorage.getItem("ProCompany") == null ? false : true;
  }

  busca_dados() {
    let URL = '/app-root';
    let text_token = '';
    let login_txt = ' ';
    let empresa = '';
    let filial = '';

    if (this.codeEditor == ' ')
     {
      gravaLog('Script Vazio ');
    }

    if (!this.ERP) {
      URL = this.url;
    } else {
      //alert('rotina chamada por dentro do Protheus')
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
      login_txt = window.btoa(this.usuario + ':' + this.senha);
    }

    if (tabela) {
      tabela.innerHTML = ''
    };

    const request = new XMLHttpRequest();
 
    request.open('GET', URL + '/qsql' + "?Query=" + this.codeEditor, true)
    
    request.timeout = 30000;
    
    if (this.ERP) {
      gravaLog('Origem: ERP');
      request.setRequestHeader('Authorization', 'Bearer ' + text_token);
      //request.setRequestHeader('TenantId', empresa + ',' + filial);
    } else {
      gravaLog('Origem: browser ');
      request.setRequestHeader('Authorization', 'Basic ' + login_txt);
    }

    request.onerror = function () {
      gravaLog('Erro ')
    };

    request.onload = () => {
      gravaLog('Final da carga ')
    };

    request.ontimeout = (e) => {
      // XMLHttpRequest timed out. Do something here.
      gravaLog(request.readyState + '|' + request.status + '|' + 'Timeout 30 segundos ')
    };

    request.onreadystatechange = function () {
      if (request.readyState === 4 && request.status === 200) {
        let dados = JSON.parse(request.responseText);
        let meta_results = dados.meta;
        let tabela_dados = dados.objects;
        let lista_de_campos = Object.keys(tabela_dados[0]);

        const table = document.getElementById('table')

        const row = tabela?.insertRow();

        gravaLog('Obtendo dados... ')
        
        for (const celula of lista_de_campos) {
          const cell = row?.insertCell();
          if (cell) {
            cell.outerHTML = '<th height="20">' + celula + '</th>';
          }
          else {
            console.log('erro cabecalho');
            gravaLog('erro cabecalho');
          }

        };

        for (const element of tabela_dados) {
          const row = tabela?.insertRow();
          for (const celula of lista_de_campos) {
            const cell = row?.insertCell();
            if (cell) {
              cell.innerHTML = element[celula];
            }
            else {
              gravaLog('erro celula');
              console.log('erro celula');
            }
          };
        };

      }
      else {
        //responseText

        switch (request.readyState) {
          case 0:
            gravaLog('UNSENT...');
            break;
          case 1:
            gravaLog('OPENED...');
            break;
          case 2:
            gravaLog('HEADERS_RECEIVED...');
            break;
          case 3:
            gravaLog('LOADING...');
            break;
          case 4:
            gravaLog('DONE...');
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

}

