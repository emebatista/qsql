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
    let empresa = '01';
    let filial = '01';
    let URL = 'http://192.168.60.43:8084/rest';
    let text_token = '';
    let usuario = '';
    let senha = '';
    let script = this.codeEditor;
    let ERP = sessionStorage.getItem("ProCompany") == null ? false : true;

    switch (cliente) {
      case 'polimaquinas': {
        usuario = 'admin';
        senha = 'admpol13';
        URL = 'http://172.30.50.50:8103/rest';
        break;
      }
      case 'reval': {
        usuario = 'emerson.batista';
        senha = 'lda03';
        URL = 'http://192.168.60.43:8084/rest';
        break;
      }
    }

    if (!ERP) {
      //alert('rotina chamada fora do Protheus');
    }

    /* componentes html */
    const tabela = document.getElementById('tabela') as HTMLTableElement | null;

    /* constantes do ERP */
    if (ERP) {
      empresa = JSON.parse(sessionStorage.getItem("ProCompany")!);
      filial = JSON.parse(sessionStorage.getItem("ProBranch")!);
      URL = window.location['origin']+'/app-root';
      text_token = JSON.parse(sessionStorage.getItem("ERPTOKEN")!)['access_token'];
    }
    const request = new XMLHttpRequest();
    const login = btoa(usuario + ':' + senha) as string;
    //   const login = Buffer.toString(usuario + ':' + senha) as string;

    if (tabela) {
      tabela.innerHTML = ''
    };

    console.log(URL + '/qsql' + + "?Query=" + script);
    request.open('GET', URL + '/qsql' + "?Query=" + script, false)
    if (ERP) {
      request.setRequestHeader('Authorization', 'Bearer ' + text_token);
     // request.setRequestHeader('TenantId', empresa + ',' + filial);
    } else {
      request.setRequestHeader('Authorization', 'Basic ' + login);
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
          if (cell) { cell.outerHTML = '<th>' + celula + '</th>'; }
        };

        for (const element of tabela_dados) {
          const row = tabela?.insertRow();
          for (const celula of lista_de_campos) {
            const cell = row?.insertCell();
            if (cell) { cell.innerHTML = element[celula]; }
          };
        };

      }
    }
    request.send()
  };
  
  ngOnInit() {
    this.restore();
  }

  restore() {
    this.codeEditor = '';
  }

}

