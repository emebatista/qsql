import { Component, OnInit } from '@angular/core';
import { timestamp } from 'rxjs';

@Component({
  selector: 'app-historico-comandos',
  templateUrl: './historico-comandos.component.html'
})
export class HistoricoComandosComponent implements OnInit {

  constructor() { }

  ngOnInit(): void {
  };
   
}

export function gravaLog(mensagem: string) {
  const timeElapsed = Date.now();
  const today = new Date(timeElapsed);

  const historico = document.getElementById('historico-comandos') as HTMLTableElement | null;

  const row = historico?.insertRow();

  const cell = row?.insertCell();
  if (cell) {
    cell.outerHTML = '<th height="20"> <p class="line2"> '+ today.toUTCString() +' | ' +mensagem+' </p> </th>';
  }

};
