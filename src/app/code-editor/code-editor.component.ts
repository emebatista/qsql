import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-code-editor',
  templateUrl: './code-editor.component.html',
  styleUrls: ['./code-editor.component.css']
})
export class CodeEditorComponent implements OnInit {
  codeEditor: string;
  constructor() {
    this.codeEditor = '';
  }

  busca_dados() {
    let cliente = ''
    let URL = '/app-root';
    let text_token = '';
    let login = ' ';
    let login_txt = ' ';
    let senha = '';
    let empresa = '';
    let filial = '';
    let script = this.codeEditor;
    let ERP = sessionStorage.getItem("ProCompany") == null ? false : true;
    script = this.codeEditor;
    if (!ERP) {
      let new_login = prompt('Digite usuario', 'admin');
      let new_senha = prompt('Senha', ' ');
      login = new_login ? new_login : ' ';
      senha = new_senha ? new_senha : ' ';
    } else {
      //alert('rotina chamada por dentro do Protheus')
    }
    /* componentes html */
    const tabela = document.getElementById('tabela') as HTMLTableElement | null;
    /* constantes do ERP */
    if (ERP) {
      empresa = JSON.parse(sessionStorage.getItem("ProCompany")!)['Code']; //JSON.parse(sessionStorage.getItem("ProCompany")!);
      filial = JSON.parse(sessionStorage.getItem("ProBranch")!)['Code']; //JSON.parse(sessionStorage.getItem("ProBranch")!);
      URL = window.location['origin'] + '/app-root';
      text_token = JSON.parse(sessionStorage.getItem("ERPTOKEN")!)['access_token'];
    }
    else {
      login_txt = window.btoa('admin' + ':' + ' ');
    }

    if (tabela) {
      tabela.innerHTML = ''
    };

    const request = new XMLHttpRequest();
 
    request.open('GET', URL + '/qsql' + "?Query=" + script, false)
    if (ERP) {
      request.setRequestHeader('Authorization', 'Bearer ' + text_token);
      //request.setRequestHeader('TenantId', empresa + ',' + filial);
    } else {
      request.setRequestHeader('Authorization', 'Basic ' + login_txt);
    }

    request.onreadystatechange = function () {
      if (request.readyState === 4 && request.status === 200) {
        let dados = JSON.parse(request.responseText);
        let meta_results = dados.meta;
        let tabela_dados = dados.objects;
        let lista_de_campos = Object.keys(tabela_dados[0]);

        const table = document.getElementById('table')

        const row = tabela?.insertRow();

        for (const celula of lista_de_campos) {
          const cell = row?.insertCell();
          if (cell) {
            cell.outerHTML = '<th height="20">' + celula + '</th>';
          }
          else {
            console.log('erro cabecalho');
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
              console.log('erro celula');
            }
          };
        };

      }
    }
    request.send();
  };

  ngOnInit() {
    this.restore();
  }

  restore() {
    this.codeEditor = '';
  }

}

