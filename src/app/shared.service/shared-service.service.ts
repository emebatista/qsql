import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class SharedService {
  public sharedVariable: any;
  private sharedVariableSubject: Subject<any> = new Subject<any>();

  constructor() { }

  setSharedVariable(value: any) {
    this.sharedVariable = value;
    this.sharedVariableSubject.next(value);
  }

  getSharedVariable() {
    return this.sharedVariableSubject.asObservable();
  }

}
