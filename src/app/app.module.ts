import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { PoModule } from '@po-ui/ng-components';
import { RouterModule } from '@angular/router';
import { PoTemplatesModule } from '@po-ui/ng-templates';
import { PoCodeEditorModule } from '@po-ui/ng-code-editor';
import { ResultTableComponent } from './result-table/result-table.component';
import { CodeEditorComponent } from './code-editor/code-editor.component';
import { FormsModule } from '@angular/forms';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HistoricoComandosComponent } from './historico-comandos/historico-comandos.component';
import { DisclaimerComponent } from './disclaimer/disclaimer.component';
import { SharedService } from './shared.service/shared-service.service';

@NgModule({
  declarations: [
    AppComponent,
    ResultTableComponent,
    CodeEditorComponent,
    HistoricoComandosComponent,
    DisclaimerComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    PoModule,
    RouterModule.forRoot([]),
    PoTemplatesModule,
    PoCodeEditorModule,
    FormsModule,
    BrowserAnimationsModule
  ],
  providers: [SharedService],
  bootstrap: [AppComponent]
})
  
export class AppModule { }
