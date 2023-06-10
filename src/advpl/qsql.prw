#include "rwmake.ch"
#include "topconn.ch"
#include "totvs.ch"
#include "vkey.ch"
#include "colors.ch"
#INCLUDE "FILEIO.CH"
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "RestFul.CH"
#DEFINE NUM_INIS 25
#DEFINE STEP_BUTTON 8.9

#DEFINE CRLF Chr(13)+Chr(10)

/*/{Protheus.doc} QSQL
Fun��o para abrir executar consultas SQL no banco de dados
@author Emerson D Batista
@since 11/12/2017
@version 1.0
/*/

User Function AfterLogin()
	SetKey( K_SH_F10, { || u_QSQLWEB() } )
	SetKey( K_SH_F11, { || u_CFGQSQL() } )
	SetKey( VK_F11  , { || u_CFGQSQL() } )
Return nil

User Function QSQL(cFraseAuto,_aPosicoes,_oJanela)
	u_CFGQSQL(cFraseAuto,_aPosicoes,_oJanela)
Return nil 

User Function CFGQSQL(cFraseAuto,_aPosicoes,_oJanela)
	Local cRPO2
	Private cTemp    	:= "01"
	Private _cMyAlias 	:= ""
	Private _cQueryTxt 	:= "" //space(500)//"Ctrl + Down para mostrar os campos (sair ESC)"+ CRLF +"F5 para executar a query"+CRLF
	Private cTitulo     := "QSQL"
	Private a_Cmps		:= {"D_E_L_E_T_"}
	Private cResult     := ""
	Private _cRet       := ""
	Private c_Pth 		:= ""
	Private c_Dtmp 		:= ""
	Private c_Hst 		:= ""
	Private lAdmin  	:= .F.
	Private xTReport    := ''
	Private cSayT 		:= Space(100)
	Private oSayT       := nil
	Private lQuery      := .T.
	Private aSelCampos  := {}
	Private pl_Trace 	:= .F.
	Private cBarra      := IIF(GetRemoteType()== 2,"/","\")
	Private cListPerm


	If Type("cFilAnt") == "U"
		RPCCLEARENV()
		RPCSetType(2)
		RPCSetEnv("01","0101","","","","",{})
	EndIf

	aListaPerm := fBuscaPerm()
	aBloqueios := fBloqueios()

	if TCSqlReplay(4, "") == .T.
		pl_Trace := .T.
	Endif

	If ! IsInCallStack("U_SqlFile")
		If !(FWIsAdmin( __cUserID ) ) .AND. GetNewPar("MV_X_RSQL",.F.)
//			MsgStop(' O usuario ' + __cUserID + ' nao pertence ao grupo de administradores!')
			lAdmin := .F.
//			Return
		Else
			lAdmin := .T.
			IF GetNewPar("MV_X_QSQL1",.F.) .AND. MsgNoYes("Abrir SqlFile?")
				SetKey( VK_F11, NIL )

				While U_SqlFile()
				EndDo

				SetKey( VK_F11, { || U_CFGQSQL() } )

				Return
			Endif
		Endif
	Endif
	//_cQueryTxt += space(500) //" <% e %> definem parametros. Ex. E5_DATA >= <%data_inicial%> "

	If !Empty(cFraseAuto)
		_cQueryTxt := cFraseAuto
	EndIf

	cRPO := GetSrvProfString("SourcePath", "\undefined")
	cRPO2:= cRPO

	If RAT("/",cRPO)>0
		nPos := RAT("/",cRPO)
		cRPO := Space(30)+"Data Promocao RPO: "+DTOC(STOD(Substr(cRPO2,nPos+1,8)))
		cRPO := cRPO + " Hora: "+Substr(cRPO2,nPos+9,2)+":"+Substr(cRPO2,nPos+11,2)+":"+Substr(cRPO2,nPos+13,2)
	EndIf

	c_Hst := "\" + GetRmtInfo()[1]

	If GetRemoteType() == 2

		c_Dtmp := "l:" + StrTran(GetTempPath(),'\','/')
		c_Pth := "l:" + StrTran(GetTempPath(),'\','/') + 'cfgqsql.tmp'

	Else

		c_Dtmp := GetTempPath(.T., .F.) + 'qsql\'
		c_Pth := GetTempPath(.T., .F.) + 'qsql\cfgqsql.tmp'

		If ! ExistDir(GetTempPath(.T., .F.) + 'qsql\')
			MakeDir(GetTempPath(.T., .F.) + 'qsql\')
		EndIf 

	Endif

	If Empty(_aPosicoes)
		DEFINE MSDIALOG oDlg1 TITLE "DM Tools - QSQL "+SPACE(150)+cRPO From 001,001 To 040,150
		DEFINE FONT oFont NAME "Menlo, Monaco, 'Courier New', monospace" SIZE 0, -12 BOLD
		DEFINE FONT oFont2 NAME "Menlo, Monaco, 'Courier New', monospace" SIZE 0, -12
		oDlg1:lEscClose     := .F. //Nao permite sair ao se pressionar a tecla ESC.

		oTMultiget2 := TMultiget():Create(oDlg1,{|u| if(Pcount()>0,_cQueryTxt:=u,_cQueryTxt)},001,001,520,150,oFont,,,,,.T.,,,,,,,,,,,.T.)
		
		oTMultiget2:lReadOnly := !lAdmin 

		@ 010 	   ,525 SAY    "____________________"   OF oDlg1 pixel color CLR_HBLUE

		@ 151,010 SAY oSayT     VAR cSayT     OF oDlg1 pixel color CLR_HBLUE


		If Empty(cFraseAuto) .and. File(c_Pth)
			nHandle := FT_FUse(AllTrim(c_Pth))

			If nHandle == -1
				MessageBox('Nao foi possivel ler o arquivo ' + c_Pth , 'AVISO', 16)
			Else

				FT_FGoTop()
				While ! FT_FEof()
					oTMultiget2:AppendText(Alltrim(FT_FReadLn()) + CRLF)
					//_cQueryTxt += Alltrim(FT_FReadLn()) + CRLF
					FT_FSkip()
				EndDo
				FT_FUSE()
			EndIf
		Else
			If empty(cFraseAuto)
				oTMultiget2:AppendText("Ctrl + Down para mostrar os campos (sair ESC)"+ CRLF +"F5 para executar a query"+ CRLF + CRLF +"SELECT TOP 10 * FROM"+ CRLF +"WHERE D_E_L_E_T_ = ' '"+ CRLF)
			EndIf
		Endif

		oBtn00 := TButton():New( 001                , 525, "&Executa (F5)",oDlg1 ,{|| fRun() }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F. )
		oBtn01 := TButton():New( 010+STEP_BUTTON*01 , 525, "E&xporta Dados" ,oDlg1 ,{|| fExport() }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F. )
		oBtn05 := TButton():New( 010+STEP_BUTTON*05 , 525, "Abrir Tabela"    	,oDlg1 ,{|| fDicio()  }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)

	EndIf

	If Empty(_aPosicoes)

		SetKey( VK_F5 ,{|| fRun()})
		SetKey( 75    ,{|| LstCmp()})

		oBtn02 := TButton():New( 010+STEP_BUTTON*02, 525, "Abrir Script" ,oDlg1 ,{|| Open() }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F. )

		If lAdmin
			oBtn03 := TButton():New(010+STEP_BUTTON*03 ,525,"Salvar"   			,oDlg1 ,{|| Save()  }  , 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn04 := TButton():New(010+STEP_BUTTON*04 ,525,"Exec.Formula"   	,oDlg1 ,{|| Terminal()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn05 := TButton():New(010+STEP_BUTTON*05 ,525,"Abrir Tabela"    	,oDlg1 ,{|| fDicio()  }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn06 := TButton():New(010+STEP_BUTTON*06 ,525,"Historico"			,oDlg1 ,{|| ShwHst(0)} , 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn07 := TButton():New(010+STEP_BUTTON*07 ,525,"Limpa Hist"		    ,oDlg1 ,{|| ShwHst(1) }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn08 := TButton():New(010+STEP_BUTTON*08 ,525,"Muda RPO"			,oDlg1 ,{|| u_MudaAmb() }, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn00 := TButton():New(010+STEP_BUTTON*09 ,525,"Copia RPO"			,oDlg1 ,{|| u_Promove()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn10 := TButton():New(010+STEP_BUTTON*10 ,525,"Comando no Srv."	,oDlg1 ,{|| fPowerShell()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn11 := TButton():New(010+STEP_BUTTON*11 ,525,"Copia Arquivos"	    ,oDlg1 ,{|| fCopiar()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn12 := TButton():New(010+STEP_BUTTON*12 ,525,"SQL File"	       	,oDlg1 ,{|| u_SqlFile()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			oBtn13 := TButton():New(010+STEP_BUTTON*13 ,525,"Gera Fonte TReport" ,oDlg1 ,{|| u_GeraTReport()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
			btnTrace := TButton():New(010+STEP_BUTTON*15 ,525,Iif(pl_Trace,"End Trace","Start Trace"),oDlg1 ,{|| Trace()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
		EndIf

		oBtn14   := TButton():New(010+STEP_BUTTON*14 ,525,"Help",oDlg1 ,{|| fHelp()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)
		oBtn16   := TButton():New(010+STEP_BUTTON*16 ,525,"Sair",oDlg1 ,{|| oDlg1:End()}, 55,09,,,.F.,.T.,.F.,,.F.,,,.F.)

		Activate Dialog oDlg1 centered
		SetKey( VK_F5, Nil )
		SetKey( 75,Nil)

	Else

		If Empty(_aPosicoes)
			fRun()
			fExport()
		Else
			fRun(_aPosicoes,_oJanela)
		EndIF

	EndIf

Return

Static Function Trace()
	Local cMessage := ""
	Local c_Log := "/qsqltrace.log"
	Local c_Aux := ""
	Local c_Lnh := ""
	Local n_Op := 0

	If ! pl_Trace
		if TCSqlReplay(1, @cMessage) == .F.
			Aviso("Atencao","Nao existe a implementacÃ£o")
			Return
		endif

		If ! LockByName("QSQLTRACE.LOG",.T.,.T.)
			Aviso("Atencao","Tracer ja Habilitado")
			Return

		Endif

		fErase(AllTrim(c_Log))

		// inicia o TCSqlReplay
		cMessage := c_Log
		TCSqlReplay(2, @cMessage)

		// liga o log de rotinas internas
		cMessage := "1"
		TCSqlReplay(6, @cMessage)

		// // altera o valor de call stack
		cMessage := FWInputBox("Informe a quantidade da Call Stack", "1")
		TCSqlReplay(7, @cMessage)

		cMessage := ""
		if TCSqlReplay(4, @cMessage) == .T.
			Aviso("Atencao","Trace foi iniciado os processos ficarÃ£o mais lentos")
		endif
		pl_Trace := .T.
		btnTrace:cTitle := "End Trace"
	Else

		// Finaliza o TCSqlReplay
		TCSqlReplay(3, @cMessage)

		If File(c_Log)
			nHandle := FT_FUse(AllTrim(c_Log))

			If nHandle == -1
				MessageBox('Nao foi possivel ler o arquivo ' + c_Log , 'AVISO', 16)
			Else
				n_Op := Aviso("Visualizar", "Deseja visualizar o arquivo? "+ CRLF +"Rootpath+"+c_Log,{"Sim","Nao"})
				If n_Op == 1
					FT_FGoTop()
					While ! FT_FEof()
						c_Lnh := FT_FReadLn() + CRLF

						c_Aux += c_Lnh

						FT_FSkip()

					EndDo
					FT_FUSE()

					oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,c_Aux:=u,c_Aux)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)
				Endif

			EndIf
		Endif

		pl_Trace := .F.
		UnLockByName("QSQLTRACE.LOG",.T.,.T.)

		btnTrace:cTitle := "Start Trace"
	EndIf

Return



Static Function fDicio()
	//teste svn
	Static    cArqDic  := "SX3"
	Static    cFiltro  := Space(200)
	aPergs  := {}
	aRet    := {}
	Set(_SET_DELETED, .F.)

	aCombo := aListaPerm

	//aAdd( aPergs ,{2,"Tabela","SFT"   ,aCombo,90,"",.F.})

	If lAdmin
		AADD(aCombo,{"SX1","Dicionario"})
		AADD(aCombo,{"SX2","Dicionario"})
		AADD(aCombo,{"SX3","Dicionario"})
		AADD(aCombo,{"SX5","Dicionario"})
		AADD(aCombo,{"SX6","Dicionario"})
		AADD(aCombo,{"SX7","Dicionario"})
		AADD(aCombo,{"SIX","Dicionario"})
		AADD(aCombo,{"SXB","Dicionario"})
		AADD(aCombo,{"SXK","Dicionario"})
	EndIf

	cArqDic := SelTab(aCombo)

//	aAdd( aPergs ,{1,"Alias da tabela ",cArqDic ,"!!!",'u_fVldDic()',,'.T.',40,.F.})

	//   aAdd( aPergs ,{1,"Filtro Registros ",cFiltDic,"@!",'.T.',,'.T.',100,.F.})
	Begin Sequence

		If Empty(cArqDic)
			Break
		EndIf

		If ! ( cArqDic $ "SX1,SX2,SX3,SX4,SX5,SX6,SX7,SIX,SXB,SXK" )

			aSelCampos := SelCampos(cArqDic)

			If len(aSelCampos) > 0
				_cMyAlias := cArqDic
			else
				FWAlertError("Nenhum campo selecionado!","Alerta")
				break
			EndIf

			DbSelectArea(_cMyAlias)

			cFiltro := DispExpr()

			If ! Empty(cFiltro)

				If MsgYesNo("Pre-Visualiza dados?","Confirma")
					MsAguarde({|| DbSetfilter({|| &(cFiltro)}, cFiltro) },"Filtrando","Aguarde...")
					fShowTrab(cArqDic,aSelCampos)
				Else
					MsAguarde({|| DbSetfilter({|| &(cFiltro)}, cFiltro) },"Filtrando","Aguarde...")
				EndIf
			Else
				Break
			Endif

		Else

			DbSelectArea(cArqDic)
			cFiltro := DispExpr()

			If ! Empty(cFiltro)
				DbSetfilter({|| &(cFiltro)}, cFiltro)
			Else
				DbClearFilter()
			Endif

			fOpenTab(cArqDic)

		EndIf

	End Sequence
	Set(_SET_DELETED, .T.)
	lQuery := .F.

Return nil

Static Function fOpenTab(_cAlias)
	Local oBrow
	Local cPict
	Local nPx
	Local nI
	Local cAlign
	Private aEstrut := {}
	lShared := .T.
	lRead   := .F.

	DbSelectArea(_cAlias)

	nPx := 1

	lNewStru	:= .F.

	oBrow := MsBrGetDBase():New( 160, 001, 580, 120,,,, oDlg1,,,,,,,,,,,, .F., _cAlias, .T.,, .F.,,, )
	//oBrow:Align := CONTROL_ALIGN_ALLCLIENT
	oBrow:nAt := 1

	aEstrut := DbStruct()

	For nI:= 1 to Len(aEstrut)
		If aEstrut[nI,2] <> "M"
			cAlign := "LEFT"
			cPict := ""
			If aEstrut[nI,2] == "N"
				cAlign := "RIGHT"
				If aEstrut[nI,4] >0
					cPict := Replicate("9",aEstrut[nI,3]-(aEstrut[nI,4]+1)) + "." + Replicate("9",aEstrut[nI,4])
				Else
					cPict := Replicate("9",aEstrut[nI,3])
				EndIf
			EndIf
			oBrow:AddColumn( TCColumn():New( aEstrut[nI,1], &("{ || "+_cAlias+"->"+aEstrut[nI,1]+"}"),cPict,,,cAlign) )
		Else
			oBrow:AddColumn( TCColumn():New( OemToAnsi(aEstrut[nI,1]), { || "Memo" },,,,,.F.) )
		EndIf
	Next

	oBrow:lColDrag   := .T.
	oBrow:lLineDrag  := .T.
	oBrow:lJustific  := .T.
	oBrow:blDblClick := {|| fEditCel(oBrow,oBrow:nColPos,.f.)} //'Read Only!'
	oBrow:Cargo		 := {|| fEditCel(oBrow,oBrow:nColPos,.f.)}
	oBrow:nColPos    := 1
	//oBrow:bChange	 := {|| SduRefreshStatusBar() }
	//oBrow:bGotFocus	 := {|| SduRefreshStatusBar() }
	oBrow:bDelOk	 := {|| fDeleteRecno(),oBrow:Refresh(.f.)}
	oBrow:bSuperDel	 := {|| fDeleteRecno(.F.),oBrow:Refresh(.f.)}
	oBrow:bAdd		 := {|| iIf( ApMsgYesNo("Adicionar Registro","Confirma?"),dbAppend(),)} //
	oBrow:SetBlkColor({|| If(Deleted(),CLR_WHITE,CLR_BLACK)})
	oBrow:SetBlkBackColor({|| If(Deleted(),CLR_LIGHTGRAY,CLR_WHITE)})

	oBrow:Refresh()
Return nil

User Function fVldDic()
	Local lReturn := .F.
	Local cAlias  := &(ReadVar())

	If lAdmin
		lReturn := .T.
	Else
		lReturn := cAlias $ cListPerm
	EndIf

	If !lReturn
		FwAlertError("Tabela Bloqueada para Consulta.","Aten��o")
	ENDIF

Return lReturn


Static Function fRun(_aPosicoes,_oJanela)
	Local aCpoBrw	:= {}
	Local cResult   := ""
	Local aStruct := {}
	Local _i := 0
	Local j := 0
	Local a_Qry := {}
	Local n_Pos := iif(type("oTMultiget2")=='O',oTMultiget2:nPos,1)
	Local n_TPos := 0
	Local n_PsBlB := 1
	Local n_PsBlE := 1
	Local a_QryTxt := {}

	cSayT :=  " "
	cSayTI := " "
	cSayTF := " "
	oSayT:Refresh()

	If type("oBrowseSQL")=="O" .or. type("oResult") == "O"
		oBrowseSQL:End()
	EndIf

	if type("oResult") =="O"
		oResult:End()
	endif

	//	If File(c_Pth)
	//		If FErase(c_Pth,,.T.) = -1
	//			MessageBox('Nao foi possivel excluir o arquivo ' + c_Pth , 'AVISO', 16)
	//		Endif
	//	Endif
	//
	//	Sleep(100)

	If Empty(_aPosicoes)
		MemoWrite(c_Pth,_cQueryTxt)
		cBkpSql := _cQueryTxt
		_cQueryTxt := Ltrim(StrTran(_cQueryTxt,CRLF,CRLF+"§$@"))
		a_Qry := StrToArray(_cQueryTxt,CRLF)
		n_PsBlE := Len(a_Qry)
		For _i := 1 to Len(a_Qry)
			a_Qry[_i] := StrTran(a_Qry[_i],"§$@","")
			if n_TPos < n_Pos
				If Empty(a_Qry[_i])
					n_PsBlB := _i
				Endif
			Endif
			n_TPos += Len(a_Qry[_i] + CRLF)

			if n_TPos > n_Pos
				If Empty(a_Qry[_i])
					n_PsBlE := _i
					Exit
				Endif
			Endif
		Next
		_cQueryTxt := ""
		For _i := n_PsBlB to n_PsBlE
			If At('--',a_Qry[_i]) > 0
				If At('--',Alltrim(a_Qry[_i])) > 1
					_cQueryTxt += SubStr(AllTrim(a_Qry[_i]),1,At('--',Alltrim(a_Qry[_i])) - 1)  + " "
				Endif
			Else
				_cQueryTxt += a_Qry[_i] + " "
			Endif

			If SubStr(AllTrim(_cQueryTxt),Len(AllTrim(_cQueryTxt)),1)==';'
				aadd(a_QryTxt,_cQueryTxt)
				_cQueryTxt := ""
			Endif

		Next

		For _i:=1 to Len(a_QryTxt)
			_cQueryTxt +=  a_QryTxt[_i]
		Next

	EndIf

	_i:=1
	_cOper  := {"DROP","TRUNCATE","INSERT","UPDATE","DELETE"}
	lSelect := .T.

	If !lAdmin 
		For _i:=1 to Len(_cOper)
			If AT(_cOper[_i],UPPER(_cQueryTxt))>0
				APMsgAlert("Alteracao de dados NAO permitida!",cTitulo)
				Return
			Endif
		Next
	EndIf 
	
	//- Validação adicional pra gente não cair nas próprias armadilhas de dar select/update sem where
	if AT("TOP",UPPER(_cQueryTxt))==0 .and. AT("WHERE",UPPER(_cQueryTxt))==0 .and. AT("DISTINCT",UPPER(_cQueryTxt))==0
		if !MsgYesNo("Deseja realizar esta operacao sem filtros?","Confirma")
			Return
		endif
	endif
	nStart  := 0
	nFinish := 0
	lParse  := .T.

	If lSelect

		_cQueryTxt :=  AllTrim(fParseParam(_cQueryTxt)[2])
		cSayTI :=  Time()
		cSayT := "Inicio: " + cSayTI
		oSayT:Refresh()

		If !fPerm(_cQueryTxt)
			APMsgAlert("Script acessa tabelas bloqueadas","Erro")
			Return .f.
		EndIf

		cSayTF :=  Time()
		cSayT += " Fim: " + cSayTF + " - " + ELAPTIME( cSayTI, cSayTF )

		cSayTI := cSayTF
		oSayT:Refresh()

		GrvHst(_cQueryTxt + CRLF + cSayT)

		oSayT:Refresh()

		IF Select("WORK1")
			WORK1->(DbCloseArea())
		EndIf

		cTemp := Soma1(cTemp)
		_cMyAlias := "XDBF"+cTemp

		IF SELECT(_cMyAlias )
			DbSelectArea(_cMyAlias)
			DbCloseArea()
		EndIf

		aRet := fRunQuery(_cQueryTxt, "WORK1")

		If !aRet[1]
			_cRet = TCSQLERROR()
			oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,_cRet:=u,_cRet)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)
			_cRet = TCSQLERROR()
			_cQueryTxt := cBkpSql
		EndIf 

		If !Select("WORK1")
			//_cQueryTxt := cBkpSql
			Return .f.
		EndIf

		DBSELECTAREA("WORK1")
		DBGOTOP()
		_aStruct:=DbStruct()
		aStruct := {}
		For j:= 1 to Len(_aStruct)
			If !AllTrim(_aStruct[j,1]) $ "R_E_C_N_O_ , R_E_C_D_E_L_ , D_E_L_E_T_"
				AADD(aStruct,_aStruct[j])
			EndIf
			aStruct[Len(aStruct),1] := Pad(aStruct[Len(aStruct),1],10)
		Next
		aCpoBrw:={}
		_i:=1
		dbSelectArea("SX3")
		dbSetOrder(2)

		a_Cmps := {"D_E_L_E_T_=''","ORDER BY R_E_C_N_O_ DESC"}
		For _i:=1 to Len(aStruct)
			if dbSeek(aStruct[_i][1])
				cLabel := AllTrim(x3Titulo()) + " ("+ AllTrim(aStruct[_i][1]) +")"
			else
				cLabel := aStruct[_i][1]
			endif
			AADD(aCpoBrw,{aStruct[_i][1],,cLabel})
			AADD(a_Cmps,aStruct[_i][1])
		Next

		aSort(a_Cmps)

		_i:=1
		dbSelectArea("WORK1")
		aSelCampos := {}
		For _i := 1 to Len(aStruct)
			If aStruct[_i,2] != "C"
				TCSetField("WORK1", aStruct[_i,1], aStruct[_i,2],aStruct[_i,3],aStruct[_i,4])
				If aStruct[_i,2] == "N"
					aStruct[_i,3]:=15
					aStruct[_i,4]:=02
				Endif
			Endif

			AADD(aSelCampos,{Alltrim(aStruct[_i,1]),_i})

		Next
		_cQueryTxt := cBkpSql

		oTempTable := FWTemporaryTable():New(_cMyAlias,aStruct)
		oTempTable:Create()
		DbSelectArea(_cMyAlias)

		FWMsgRun(,{|| fAppend() },"Aguarde","Executando 2")

		&(_cMyAlias)->(dbgotop())
		WORK1->(dbclosearea())

		If Empty(_aPosicoes)
			_aPosicoes := {160,001,295,588}
		EndIf
		oBrowseSQL := MsSelect():New(_cMyAlias,"","",aCpoBrw,.F.,"",_aPosicoes)
		oBrowseSQL:oBrowse:Refresh()

		cSayTF := Time()
		cSayT += " Montagem: " + ELAPTIME( cSayTI, cSayTF )
		oSayT:Refresh()
	else
		cResult := ""
		If Len(a_QryTxt) > 0
			//Tratativa para update e delete

			cResult := ""
			For _i := 1 to Len(a_QryTxt)
				nSqlError := TcSqlExec(a_QryTxt[_i])

				if nSqlError <> 0
					cResult += "Qry "+ StrZero(_i,5) +" Erro: " + TcSqlError() + chr(13) + chr(10)
				else
					GrvHst(a_QryTxt[_i])
					cResult += "Qry "+ StrZero(_i,5) +" executado com sucesso." + TcSqlError() + chr(13) + chr(10)
				endif
			Next
		Else
			//Tratativa para update e delete
			nSqlError := TcSqlExec(_cQueryTxt)

			if nSqlError <> 0
				cResult := TcSqlError()
			else
				GrvHst(_cQueryTxt)
				cResult := "Comando executado com sucesso."+chr(13)+chr(10)+TcSqlError()
			endif
		Endif

		oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,cResult:=u,cResult)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)

		_cQueryTxt := cBkpSql

	endif

	lQuery := .T.

RETURN

Static Function fAppend()
	Append from WORK1
Return nil

Static Function fExport()
	Private oExcel

	if Empty(_cMyAlias)
		Alert("Tabela Vazia")
		Return nil
	EndIf

	_cArquivo := AllTrim(c_Dtmp+'exporta.csv')+Space(1)

	_cDestino := ""
	aPergs := {}
	aRet   := {}
	aCombo := {"CSV","XML","DTC"}
	aAdd( aPergs ,{6,"Arquivo",_cArquivo,"",,"", 100 ,.T.,"Arquivos .* |*.*","C:\",GETF_LOCALHARD})
	aAdd( aPergs ,{2,"Formato","CSV"		,aCombo,100,"",.F.})

	If ParamBox(aPergs ,"Planilha",aRet,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.F./*lCanSave*/,.F./*lUserSave*/ )

		If cBarra == "/" // corrige retorno
			_cArquivo := StrTran(aRet[1],"\","/")
		EndIf

		_cDestino := Substr(_cArquivo,1,Len(_cArquivo)-1)
		_cArquivo := AllTrim(Substr(_cDestino,RAT(cBarra,_cDestino)+1,40))
		_cPasta   := Alltrim(Substr(_cDestino,1,RAT(cBarra,_cDestino)-1))

		If aRet[2]== "XML"
			_cArquivo := StrTran(lower(_cArquivo),".csv",".xml")
			fGeraExcel()
			MsAguarde({|| oExcel:GetXMLFile(_cArquivo) },"Gerando Planilha","Aguarde...")
			MsAguarde({|| CpyS2T( _cArquivo, _cPasta, .F. ) },"Copiando Planilha","Aguarde...")
		EndIf

		If aRet[2]== "CSV"
			_cArquivo := StrTran(lower(_cArquivo),".xml",".csv")
			MsAguarde({|| fGeraCSV() },"Gerando Arquivo CSV","Aguarde...")
		EndIf

		If aRet[2]== "DTC"
			_cArquivo := StrTran(lower(_cArquivo),".xml",".dtc")
			MsAguarde({|| fGeraDTC() },"Gerando Arquivo DTC","Aguarde...")
		EndIf

		MsgInfo("Planilha Exportada em "+_cPasta)


		If GetRemoteType() != 2

			nRet := ShellExecute("open", _cArquivo, "", _cPasta, 1)

			IF nRet <= 32
				Alert("Nao foi possivel abrir " +_cPasta+cBarra+_cArquivo+ "!")
			EndIf

		EndIf

	EndIf
Return .t.

Static Function Open()
	aPergs := {}
	aRet   := {}
	cArquivo := padr("",150)
	aAdd( aPergs ,{6,"Arquivo",cArquivo,"",,"", 90 ,.T.,"Arquivos  |*.*","C:\",GETF_LOCALHARD})

	If ParamBox(aPergs ,"Abrir",aRet)
		_cQueryTxt := MemoRead(aRet[1])
	EndIf

Return nil

Static Function Save()
	aPergs := {}
	aRet   := {}
	cArquivo := padr("",150)

	aAdd( aPergs ,{6,"Arquivo",cArquivo,"",,"", 90 ,.T.,"Arquivos |*.*","C:\",GETF_LOCALHARD})

	If ParamBox(aPergs ,"Salvar",aRet)
		If MemoWrite(aRet[1],_cQueryTxt)
			MsgInfo("Salvo com Sucesso.")
		Else
			Alert("Falha ao Criar "+aRet[1])
		EndIf
	EndIf

Return nil

Static Function LstCmp()
	Local n_Pos := oTMultiget2:nPos

	If Len(a_Cmps) <> 0
		DEFINE DIALOG oDlg TITLE "Campos" FROM 180,180 TO 380,380 PIXEL
		aItems := a_Cmps
		nList := 1

		oList2 := TListBox():Create(oDlg,001,001,{|u|if(Pcount()>0,nList:=u,nList)},aItems,100,100,,,,,.T.)
		ACTIVATE DIALOG oDlg CENTERED

		_cQueryTxt := SubStr(_cQueryTxt,1,n_Pos) + a_Cmps[nList] + SubStr(_cQueryTxt,n_Pos)

		oTMultiget2:nPos := Len(SubStr(_cQueryTxt,1,n_Pos) + a_Cmps[nList])

	Endif
RETURN

Static Function Terminal()
	Local oError := ErrorBlock({|e| MsgAlert("Mensagem de Erro: " +chr(10)+ e:Description, "ERRO")})

	IF !MsgYesNo("Confirma Execblock?","Confirma")
		Return nil
	EndIf

	cExpr := _cQueryTxt

	If !Empty(cExpr)
		Begin Sequence
			xReturn := cValToChar(&cExpr)
			cResult := chr(13)+chr(10)+xReturn
			oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,cResult:=u,cResult)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)
			Return .T.
		End Sequence
	EndIf

	ErrorBlock(oError)

Return .F.

Static Function fPowerShell()
	Local oError := ErrorBlock({|e| MsgAlert("Mensagem de Erro: " +chr(10)+ e:Description, "ERRO")})

	IF !MsgYesNo("Confirma Execucao?","Confirma")
		Return nil
	EndIf

	cExpr := _cQueryTxt

	If !Empty(cExpr)
		Begin Sequence

			lOk := .t.

			FWMsgRun(,{|| lOk := WaitRunSrv( cExpr , .T. , "C:\" )  },"Executando PowerShell","Aguarde... ")

			IF lOk
				MsgInfo("Executado com sucesso!")
			Else
				Alert("Erro na ExecucÃ£o")
			EndIf

			Return .T.
		
		End Sequence

	EndIf

	ErrorBlock(oError)

Return .F.

Static Function GrvHst(c_Qry)
	Local nHandle
	Local a_Aux := {}
	Local c_Aux := ""
	Local n_I := 0

	If File(c_Hst)
		nHandle := FT_FUse(AllTrim(c_Hst))

		If nHandle == -1
			MessageBox('Nao foi possivel ler o arquivo ' + c_Hst , 'AVISO', 16)
		Else

			FT_FGoTop()

			While ! FT_FEof()

				AADD(a_Aux, FT_FReadLn())
				FT_FSkip()

			EndDo
			FT_FUSE()
		EndIf
	EndIf
	AADD(a_Aux, DtoC(Date()) + "-" + Time() +": " + c_Qry)

	For n_I := Iif(Len(a_Aux) < 1000, 1, Len(a_Aux) - 1000) to Len(a_Aux)
		c_Aux +=  a_Aux[n_I] + CRLF
	Next

	MemoWrite(c_Hst,c_Aux)
Return

Static function ShwHst(nPar)
	Local nHandle
	Local c_Aux := ""

	If nPar == 1 .AND. MsgYesNo("Limpa Historico?","Confirma")
		fErase(AllTrim(c_Pth))
		Alert("Historico excluido! "+c_Hst)
		Return Nil
	EndIF

	If File(c_Hst)
		nHandle := FT_FUse(AllTrim(c_Hst))

		If nHandle == -1
			MessageBox('Nao foi possivel ler o arquivo ' + c_Hst , 'AVISO', 16)
		Else

			FT_FGoTop()

			While ! FT_FEof()
				c_Aux += FT_FReadLn() + CRLF
				FT_FSkip()

			EndDo
			FT_FUSE()

			oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,c_Aux:=u,c_Aux)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)

		EndIf
	EndIf
Return

/*/{Protheus.doc} MudaAmb
//TODO Rotina para alterar caminho do Ambiente
@author emebatista
@since 26/12/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function MudaAmb()
	Local cRpoOld := ""
	Local cRpoNew := ""
	Local i
	Local nPar
	Local k

	aParam := {}
	aadd(aParam,"")
	For i:= 1 to NUM_INIS
		aadd(aParam,space(180))
	Next

	cPergArq  := "MudaAmb" //"mudaamb"
	cPergArq2 := "MudaAmb2" //"mudaamb"


	aPerg      := {}

	For nPar := 1 to NUM_INIS
		cItem := StrZero(nPar,2)
		&("MV_PAR"+cItem) := aParam[nPar] := PadR(ParamLoad(cPergArq,aPerg,nPar,aParam[nPar]),180)
	Next

	aadd(aPerg,{1,"Ambiente"  ,aParam[01],"","","",".T.",90,.F.})

	For nPar := 1 to NUM_INIS
		aadd(aPerg,{1,"bin "+StrZero(nPar,2),aParam[nPar+1],"","","",".T.",180,.F.}) 	//
	Next

	aResp := {}
	If ParamBox(aPerg,"Escolha o Ambiente",aResp,,,,,,,cPergArq,.T.,.T.)
		For k:= 1 to len(aResp)
			If k>1 .and. !Empty(aResp[k])
				cRpoOld := GetPvProfString(AllTrim(aResp[1]), 'SourcePath', 'NaoEncontrado', aResp[k])
				//Alert(aResp[k]+">"+cRpoOld)
				If cRpoOld == "NaoEncontrado"
					Alert("Ambinete Nao Encontrado em "+aResp[k] + chr(10) + chr(13) + "Processo Cancelado.")
					Return .f.
				EndIf
			EndIf
		Next
		cAmbiente := AllTrim(aResp[1])
	Else
		Alert("Processo Cancelado.")
		Return .f.
	EndIf

	aResp2 := {}

	aParam2 := {}

	cRpoAux      := Substr(cRpoOld,Rat("\",Substr(cRpoOld,1,Len(cRpoOld)-1))+1,200)
	cRpoAux      := AllTrim(StrTran(cRpoAux,"\",""))
	cRpoOldAux   := cRpoAux
	cRpoNew      := Soma1(cRpoAux)
	cRpoNew    := StrTran(cRpoOld,cRpoOldAux,cRpoNew)

	aadd(aParam2,Pad(cRpoOld,100))
	aadd(aParam2,Pad(cRpoNew,100))

	aPerg2      := {}
	aadd(aPerg2,{1,"Localizar     "    ,aParam2[01],"","","",".T.",90,.F.}) 	//
	aadd(aPerg2,{1,"Substituir por"    ,aParam2[02],"","","",".T.",90,.F.}) 	//

	If ParamBox(aPerg2,"Alterar SourcePath",aResp2) //,,,,,,,cPergArq2,.T.,.T.)

		cRpoOld    := StrTran(AllTrim(aResp2[1]),"\","\\")

		cRPONew    := AllTrim(aResp2[2])

		cLog := "Arquivos Processados: "+chr(10)+chr(13)

		For k:=1 to Len(aResp)

			If k>1 .AND. !Empty(AllTrim(aResp[k]))

				cArqIni      := AllTrim(aResp[k])

				xComando    := 'powershell -Command "(Get-Content '+cArqIni+") -replace '"+cRpoOld+"' ,'"+cRpoNew
				xComando    += "' | Set-Content "+cArqIni+'" -encoding ASCII '
				qout(time()+" "+xComando)

				FWMsgRun(,{|| lOk := WaitRunSrv( xComando , .T. , "C:\" )  },"Alterando SourcePath.","Aguarde "+AllTrim(aResp[k]))

				/*
				If !WritePProString(cAmbiente, 'SourcePath', cRPONew, cArqIni)
				MsgInfo("Falha ao Atualizar "+cArqIni)
				EndIf

				If GetPvProfString(cAmbiente, "SourcePath", "NaoAchou", cArqIni) <> cRPONew
				MsgInfo("Falhou em  "+cArqIni)
				EndIf
				*/

				cLog += cArqIni + chr(10)+chr(13)

			EndIf
		Next

		MsgInfo("Processado com Sucesso!"+CHR(10)+CHR(13)+StrTran(cRpoOld,"\\","\")+">>"+cRPONew+chr(10)+chr(13)+cLog)

	Else
		Alert("Processo Cancelado!")
	EndIf

Return nil

User Function Promove()
	Local xComando  := ""
	Local aPerg 	:= {}
	Local aParam 	:= {}
	Local cPergArq 	:= "PromoveRPO"
	Local aResp  	:= {}

	aadd(aParam,Pad("C:\Totvs\Protheus\apo\" ,250))
	aadd(aParam,Pad("C:\Totvs\Protheus\apo2\",250))

	aParam[1] := PadR(ParamLoad(cPergArq,aPerg,1,aParam[1]),250)
	aParam[2] := PadR(ParamLoad(cPergArq,aPerg,2,aParam[2]),250)

	MV_PAR01 := aParam[1]
	MV_PAR02 := aParam[2]

	aadd(aPerg,{1,"RPO Origem "  ,aParam[01],"","","",".T.",160,.F.})
	aadd(aPerg,{1,"RPO Destino"  ,aParam[02],"","","",".T.",160,.F.})

	If ParamBox(aPerg,"Comando no Servidor",aResp,,,,,,,cPergArq,.T.,.T.)

		aResp[1] := AllTrim(aResp[1])
		aResp[2] := AllTrim(aResp[2])

		If Right(aResp[1],1)<>"\"
			aResp[1]+="\"
		EndIF

		If Right(aResp[2],1)<>"\"
			aResp[2]+="\"
		EndIF

		xComando := "xcopy "+ aResp[1]+"*.* "+aResp[2]+" /s /y"

		lOk := .F.

		WaitRunSrv( "MD "+aResp[2],.T., "C:\")

		FWMsgRun(,{|| lOk := WaitRunSrv( xComando , .T. , "C:\" )  },"Copia de RPO.","Copiando "+AllTrim(aResp[1])+" para "+AllTrim(aResp[2]))

		IF lOk
			MsgInfo("Executado com sucesso!")
		Else
			Alert("Erro na Execucao")
		EndIf
	EndIf

Return nil

Static Function fCopiar()

	_cOrigem  := Space(80)
	_cDestino := Space(80)

	aPergs := {}
	aRet   := {}
	//               1   2             3      4  5 6   7    8      9            10
	aAdd( aPergs ,{6,"Arq.Origem" ,_cOrigem ,"",,"", 80 ,.F.,"Arquivos  |*.*","C:\", GETF_LOCALHARD + GETF_NETWORKDRIVE})
	If ParamBox(aPergs ,"Escolha a Origem",aRet)
		_cOrigem := aRet[1]
	EndIf

	aPergs := {}
	aRet   := {}
	//               1   2             3      4  5 6   7    8      9            10
	aAdd( aPergs ,{6,"Arq.Destino",_cDestino,"",,"", 80 ,.T.,"Pastas|*.*","\", GETF_RETDIRECTORY + GETF_LOCALHARD + GETF_NETWORKDRIVE })
	If ParamBox(aPergs ,"Escolha o Destino",aRet)
		_cDestino := aRet[1]
	EndIf

	lResult := .F.

	If Substr(_cOrigem,2,1)==":" .AND. Substr(_cDestino,2,1)<> ":"
		lResult := CpyT2S(_cOrigem,_cDestino)
	EndIf

	If Substr(_cOrigem,2,1)<>":" .AND. Substr(_cDestino,2,1)== ":"
		lResult := CpyS2T(_cOrigem,_cDestino)
	EndIf

	If lResult
		MsgInfo("Executado Com Sucesso!")
	Else
		Alert("Falha de Execucao!")
	EndIF

Return nil

// Montagem do Grid
Static Function fShowTrab(_cAlias,_aCampos)
	Local oBrow
	Local cPict
	Local nPx
	Local nI
	Local cAlign
	Private aEstrut := {}
	lShared := .T.
	lRead   := .F.

	DbSelectArea(_cAlias)

	nPx := 1

	lNewStru	:= .F.

	oBrow := MsBrGetDBase():New( 160, 001, 580, 120,,,, oDlg1,,,,,,,,,,,, .F., _cAlias, .T.,, .F.,,, )
	//oBrow:Align := CONTROL_ALIGN_ALLCLIENT
	oBrow:nAt := 1

	aEstrut := DbStruct()

	For nI:= 1 to Len(aEstrut)
		If ASCAN( _aCampos, {|x| alltrim(aEstrut[nI,1]) == alltrim(x[1]) } ) > 0
			If aEstrut[nI,2] <> "M"
				cAlign := "LEFT"
				cPict := ""
				If aEstrut[nI,2] == "N"
					cAlign := "RIGHT"
					If aEstrut[nI,4] >0
						cPict := Replicate("9",aEstrut[nI,3]-(aEstrut[nI,4]+1)) + "." + Replicate("9",aEstrut[nI,4])
					Else
						cPict := Replicate("9",aEstrut[nI,3])
					EndIf
				EndIf
				oBrow:AddColumn( TCColumn():New( aEstrut[nI,1], &("{ || "+_cAlias+"->"+aEstrut[nI,1]+"}"),cPict,,,cAlign) )
			Else
				oBrow:AddColumn( TCColumn():New( OemToAnsi(aEstrut[nI,1]), { || "Memo" },,,,,.F.) )
			EndIf
		EndIf
	Next

	If lAdmin .and. .F.
		oBrow:lColDrag   := .T.
		oBrow:lLineDrag  := .T.
		oBrow:lJustific  := .T.
		oBrow:blDblClick := {|| fEditCel(oBrow,oBrow:nColPos,.f.)} //'Read Only!'
		oBrow:Cargo		 := {|| fEditCel(oBrow,oBrow:nColPos,.f.)}
		oBrow:nColPos    := 1
		//oBrow:bChange	 := {|| SduRefreshStatusBar() }
		//oBrow:bGotFocus	 := {|| SduRefreshStatusBar() }
		oBrow:bDelOk	 := {|| fDeleteRecno(),oBrow:Refresh(.f.)}
		oBrow:bSuperDel	 := {|| fDeleteRecno(.F.),oBrow:Refresh(.f.)}
		oBrow:bAdd		 := {|| iIf( ApMsgYesNo("Adicionar Registro","Confirma?"),dbAppend(),)} //
		oBrow:SetBlkColor({|| If(Deleted(),CLR_WHITE,CLR_BLACK)})
		oBrow:SetBlkBackColor({|| If(Deleted(),CLR_LIGHTGRAY,CLR_WHITE)})
	EndIf
	FWMsgRun(,{|| oBrow:Refresh() },"Aguarde","Executando...")

Return nil

// --------------------------------------------------------------------------------
// Executada a partir da Funcao lEditCol(MsGetDados), estÃ¡ Funcao permite a edicao
// do campos no Grid
Static Function fEditCel(oBrowse,nCol,lReadOnly,aStruct)
	Local oDlg
	Local oRect
	Local oGet
	Local oBtn
	Local cMacro	:= ''
	Local nRow   	:= oBrowse:nAt
	Local oOwner 	:= oBrowse:oWnd
	Local nLastKey
	Local cValType
	Local nX
	Local cPict		:= ''
	Local aItems	:= {'.T.','.F.'}
	Local cCbx		:= '.T.'
	//Local cBarMsg	:= "Altera"
	Local cField
	Local aColumns	:= oBrowse:GetBrwOrder()
	Local nField
	Local cInfo 	:= ''

	Default nCol  := oBrowse:nColPos
	Default lReadOnly := .F.

	aStruct := DbStruct()

	If Len(aColumns)<= 0 .OR. eof()
		Return
	EndIf

	If !DbRLock(recno())
		cInfo += 'Record locked by another user.'+CRLF
		IF "TOP"$RDDNAME()
			cInfo += TcInternal(53)
		Endif
		FWAlertError(cInfo,"Alerta")
		Return
	Endif

	cField := aColumns[nCol][1]
	nField := Len(cField)
	nField := Ascan(oBrowse:aColumns,{|x| AllTrim(x:cHeading) == cField})
	cField := oBrowse:aColumns[nField]:cHeading

	oRect	 := tRect():New(0,0,0,0) // obtem as coordenadas da celula (lugar onde
	oBrowse:GetCellRect(nCol,,oRect) // a janela de edicao deve ficar)
	aDim  	 := {oRect:nTop,oRect:nLeft,oRect:nBottom,oRect:nRight}

	cMacro 	 := "M->CELL"+StrZero(nRow,6)
	&cMacro	 := FieldGet(FieldPos(cField))

	nX		 := Ascan(aStruct,{|x| x[1]==cField})
	cValType := aStruct[nX,2]
	If ( cValType == "N" )
		If ( aStruct[nX,4] > 0 )
			cPict := Replicate("9",aStruct[nX,3]-(aStruct[nX,4]+1)) + "." + Replicate("9",aStruct[nX,4])
		Else
			cPict := Replicate("9",aStruct[nX,3])
		EndIf
	ElseIf ( cValType == "D" )
		cPict := "@D"
	EndIf

	If ( cValType == 'M' )
		oMainWnd:SetMsg('Para gravar, Ctrl+W',.T.) //
		SetKey(23,{|| oDlg:End(), nLastKey:=13 })
		DEFINE MSDIALOG oDlg OF oOwner FROM 000,000 TO 050,400 STYLE nOR( WS_VISIBLE, WS_POPUP ) PIXEL
		oGet := TMultiGet():New(0,0,bSetGet(&(cMacro)),oDlg,399,049,oOwner:oFont,.F.,,,,.T.,,,,,, lReadOnly,,,,.F.)
		oGet:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, 062  )
		oGet:cReadVar  := cMacro
	Else
		DEFINE MSDIALOG oDlg OF oOwner  FROM 000,000 TO 000,000 STYLE nOR( WS_VISIBLE, WS_POPUP ) PIXEL
		If ( cValType == 'L' )
			cCbx := If(&(cMacro),'.T.','.F.')
			oGet := TComboBox():New( 0, 0, bSetGet(cCbx),aItems, 10, 10, oDlg,,{|| If(cCbx=='.T.',&(cMacro):=.T.,&(cMacro):=.F.), oDlg:End(), nLastKey:=13  },,,,.T., oOwner:oFont)
			oGet:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, aDim[ 3 ] - aDim[ 1 ] + 4 )
		Else
			oGet := TGet():New(0,0,bSetGet(&(cMacro)),oDlg,0,0,cPict,,,,oOwner:oFont,,,.T.,,,,,,,lReadOnly,,,,,,,,.T.)
			oGet:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, aDim[ 3 ] - aDim[ 1 ] + 4 )
			oGet:cReadVar  := cMacro
		EndIf
	EndIf

	@ 0, 0 BUTTON oBtn PROMPT "ze" SIZE 0,0 OF oDlg
	oBtn:bGotFocus := {|| oDlg:nLastKey := VK_RETURN, oDlg:End()}

	If ( cValType == 'M' )
		ACTIVATE MSDIALOG oDlg CENTERED  ON INIT oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], 60)  VALID ( nLastKey := oDlg:nLastKey, .T. )
	Else
		ACTIVATE MSDIALOG oDlg ON INIT oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1])  VALID ( nLastKey := oDlg:nLastKey, .T. )
	EndIf

	If ( nLastKey <> 0 )
		FieldPut(FieldPos(cField),(&cMacro))
		DbUnLock()
		DbCommit()
		oBrowse:nAt := nRow
		SetFocus(oBrowse:hWnd)
		oBrowse:Refresh()
	Else
		DbUnLock()
	EndIf

Return

Static Function fDeleteRecno(lConfirm)
	Local lDeleted	:= Deleted()
	Local cText		:= If( lDeleted, 'Recuperar registro?', 'Deletar registro?' ) //###
	Local cInfo := ''

	Default	lConfirm := .T.

	If ( Empty(Alias()) )
		Return
	EndIf

	If ( EOF() )
		FWAlertError('Arquivo vazio!','Erro')
		Return
	EndIf

	If ( lConFirm )
		If ( !APMsgNoYes(cText,'Confirmar') ) //
			Return
		EndIf
	EndIf

	If !DbRLock(recno())

		cInfo += 'Record locked by another user.'+CRLF
		IF "TOP"$RDDNAME()
			cInfo += TcInternal(53)
		Endif
		//FWAlertNoYes
		FWAlertInfo(cInfo,'Alerta')

	Else

		Begin Sequence

			If ( Deleted() )
				DbRecall()
			Else
				DbDelete()
			EndIf
			DbRUnlock()
			DbCommit()

		End Sequence

		NetErr(.f.)

	Endif

Return

// Mostra uma tela de help com as funcionalidades
static function fHelp()
	MSGInfo(/*"<h1>Help QSQL</h1>" +*/;
		"<h2>Teclas rapidas do QSQL</h2>" +;
		"<b>F5:</b> Executa o comando SQL." +;
		"<br><b>CTRL + seta para baixo:</b> Abre a lista de campos." +;
		"<h2>Funcoes (botoes) do QSQL</h2>" +;
		"<b>Executa:</b> Executa o comando SQL." +;
		"<br><b>Exporta Dados:</b> Exporta o resultado da consulta no formato XML ou CSV (pode ser importado no Excel)." +;
		"<br><b>Abrir:</b> Abre qualquer arquivo para edicao (local ou remoto). Util para editar arquivos de menus, alÃ©m de scripts SQL." +;
		"<br><b>Salvar:</b> Salva o texto que esta' na tela em um arquivo. Pode ser qualquer extensÃ£o, inclusive menus." +;
		"<br><b>Exec. Formula:</b> Executa uma ou mais user functions ou scripts em ADVPL, em sequencia, separados por vÃ­gula(,)." +;
		"<br><b>Abrir Tabela:</b> Permite editar (inc./alt./exc./recuperar) das linhas (registros) de uma tabela aberta (SX ou DB)." +;
		"<br><b>Historico:</b> Carrega o Historico de comandos." +;
		"<br><b>Limpa Hist.:</b> Limpar o Historico, caso necessario." +;
		"<br><b>Mudar RPO:</b> Muda o caminho do RPO no .ini (appserver.ini), permitindo mudanca a quente. Apenas em Windows." +;
		"<br><b>Copia RPO:</b> Faz uma copia do RPO para outra pasta, facilitando a criacao de copias de seguranca." +;
		"<br><b>Comando no Srv.:</b> Executa um comando no servidor. Exemplo: reiniciar TSS, executar .BAT, etc." +;
		"<br><b>Copia Arquvos:</b> Copia arquivos da pasta local para o servidor ou vice versa. Exemplo: copia de patches ou substituicao de menu." +;
		"<br><b>Gera Fonte TReport:</b> Com base na Query carregada, abre uma tela de parametros com dados para geracao de codigo em ADVPL do relatorio correspondente no objeto TReport." +;
		"<br><b>Help:</b> Mostra esta tela de help." +;
		"<br><b>Sair:</b> Fecha este utilitario." +;
		"";
		)
return

User function SqlFile()
	Local aRet := {Space(100)}
	Local aPergs := {}
	Local l_Ret := .F.
	Local c_Sql := ""
	Local c_Arq := ""
	Local c_Pst := "\sqlfile\"

	If ! FWMakeDir(c_Pst,.T.)
		Aviso("Atencao","Inconsistencia ao criar diretorio " + c_Pst,{"Ok"})
		Return
	Endif
	//
	//6 - File
	//[2] : DescricÃ£o
	//[3] : String contendo o inicializador do campo
	//[4] : String contendo a Picture do campo
	//[5] : String contendo a validacao
	//[6] : String contendo a validacao When
	//[7] : Tamanho do MsGet
	//[8] : Flag .T./.F. Parametro Obrigatorio ?
	//[9] : Texto contendo os tipos de arquivo
	//Ex.: &quot;Arquivos .CSV |*.CSV&quot;
		//[10]: Diretorio inicial do CGETFILE()
	//[11]: Parametros do CGETFILE()

	If GetRemoteType() = 2
		aAdd( aPergs ,{6,"Arquivo"	,	aRet[1],"",'.T.','.F.',80,.T.,"Arquivos .TXT |*.TXT","SERVIDOR/sqlfile/",4})
	Else
		aAdd( aPergs ,{6,"Arquivo"	,	aRet[1],"",'.T.','.F.',80,.T.,"Arquivos .TXT |*.TXT","SERVIDOR\sqlfile\",4})
	Endif

	l_Ret := ParamBox(aPergs ,"Arquivo",@aRet,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.F./*lCanSave*/,.F./*lUserSave*/ )

	If l_Ret
		If GetRemoteType()==2
			c_Arq := c_Pst + SubStr(aRet[1],3)
		Else
			c_Arq := c_Pst + SubStr(aRet[1],2)
		Endif

		If !Empty(c_Arq)
			If File(c_Arq)
				nHandle := FT_FUse(AllTrim(c_Arq))

				If nHandle == -1
					MessageBox('Nao foi possivel ler o arquivo ' + c_Arq , 'AVISO', 16)
				Else
					FT_FGoTop()
					While ! FT_FEof()
						c_Sql += Alltrim(FT_FReadLn()) + CRLF
						FT_FSkip()
					EndDo
					FT_FUSE()
				EndIf

				U_CFGQSQL(c_Sql)
			Else
				MessageBox('O arquivo Nao foi encontrado: ' + c_Arq , 'AVISO', 16)
			Endif
		Endif
	Endif

Return l_Ret

Static Function ListaToArray(_cLista)
	Local _aReturn := {}
// Limpa caracteres especial
	_cLista := StrTran(_cLista,'{','')
	_cLista := StrTran(_cLista,'}','')
	_cLista := StrTran(_cLista,"'",'')
	_cLista := StrTran(_cLista,'"','')
	_cLista := StrTran(_cLista,';',',')

	If Len(Alltrim(_cLista))==0
		_aReturn := {}
	Else
		_aReturn := STRTOKARR( _cLista, ',' )
	EndIf

Return _aReturn

Static Function fTrataLista(_cLista)
	Local cReturn := ""
	Local aReturn := {}
	Local nItem as numeric

	aReturn := ListaToArray(_cLista )

	If Len(aReturn)>0
		cReturn := '{'
		For nItem := 1 to Len(aReturn)
			cReturn += "'"+alltrim(aReturn[nItem])+"'"
			If nItem < Len(aReturn)
				cReturn += ","
			EndIf
		Next
		cReturn += '}'
	Else
		cReturn := '{}'
	EndIf

Return cReturn

User Function GeraTReport()
	Local cQuery       :=  _cQueryTxt // SELECT A2_EST,A2_COD, A2_NOME, A2_SALDUP FROM SA2010 WHERE A2_EST = <%ESTADO%> ORDER BY A2_EST '  //<<CQUERY>>
	Local cNomeRelat   := 'QSQLR001' // <<NOME_RELATORIO>>
	Local cPerg        := "QSQL01" // <<CPERG_RELATORIO>>
	Local cTituloRel   := "Consulta Generica                                      " // <<TITULO_RELATORIO>>
	Local aCabGrp      := Pad("",50) //<<CAB_GRUPO>>  Campos precisam vir na query. Se nao tiver agrupamento, passar vazio
	Local aCabGrpTxt   := Pad("",50) // <<CAB_GRUPO_TXT>> // legendas das sessao de cabecalho
	Local aOrdem       := Pad("",50) // <<AORDEM>> // Campos precisam vir na query
	Local aOrdemTxt    := Pad("",50)  // <<AORDEM_TXT legendas das ordens
	Local aGerarTotais := Pad("",50) // <<AGERAR_TOTAIS>>
	Local cNomeFunc	   := "QSQLREP   "  // <<NOME_FUNC>>
	Local nOrientacao  := '2'  // <<NORIENTACAO>>
	Local cAutor       := Pad('Admin',20)
	Local cData 	   := Date()
	Local cCliente	   := Pad('Em Geral',70)

	aPrompt := {}
	AADD( aPrompt ,{1,"Nome Funcao"		      , cNomeFunc			, "@!",  , , '.T.', Len(cNomeFunc)*3, .T.})
	AADD( aPrompt ,{1,"Nome Relatorio"		  , cNomeRelat		, "@!",  , , '.T.', Len(cNomeRelat)*2, .T.})
	AADD( aPrompt ,{1,"TÃ­tulo Relatorio"	  , cTituloRel	,     ,  , , '.T.', Len(cTituloRel)*2, .T.})
	AADD( aPrompt ,{1,"Perguntas "			  , cPerg				, "@!",  , , '.T.', Len(cPerg)*2, .F.})
	AADD( aPrompt ,{1,"Quebra de Agrupamento ", aCabGrp		, "@!",  , , '.T.', Len(aCabGrp)*2, .F.})
	AADD( aPrompt ,{1,"Legendas da Quebra"	  , aCabGrpTxt	, ,  , , '.T.', Len(aCabGrpTxt)*2, .F.})
	AADD( aPrompt ,{1,"Ordens do Relatorio "  , aOrdem			    , "@!",  , , '.T.', Len(aOrdem)*2, .F.})
	AADD( aPrompt ,{1,"Legendas da Ordem"	  , aOrdemTxt			, ,  , , '.T.', Len(aOrdemTxt)*2, .F.})
	AADD( aPrompt ,{1,"Campos a Totalizar "	  , aGerarTotais	    , "@!",  , , '.T.', Len(aGerarTotais)*2, .F.})
	AADD( aPrompt ,{2,"Paisagem/Retrato"	  , nOrientacao		    ,{"1=Retrato", "2=Paisagem"},60 , "", .T.})
	AADD( aPrompt ,{1,"Autor "				  , cAutor				, "@!",  , , '.T.', Len(cAutor)*2, .T.})
	AADD( aPrompt ,{1,"Data"				  , cData				, "@!",  , , '.T.', 40, .T.})
	AADD( aPrompt ,{1,"Para Uso De"		      , cCliente			, "@!",  , , '.T.', Len(cCliente)*2, .T.})

	aResp2   := {}
	If ParamBox(aPrompt,"Parametros",aResp2,,,,,,,'QSQLGERATREPORT',.T.,.T.)
		cNomeFunc	:= aResp2[1]
		cNomeRelat	:= aResp2[2]
		cTituloRel	:= aResp2[3]
		cPerg		:= aResp2[4]
		aCabGrp	    := fTrataLista(aResp2[5])
		aCabGrpTxt	:= fTrataLista(aResp2[6])
		aOrdem		:= fTrataLista(aResp2[7])
		aOrdemTxt	:= fTrataLista(aResp2[8])
		aGerarTotais := fTrataLista(aResp2[9])
		nOrientacao	 := aResp2[10]
		cAutor		:= aResp2[11]
		cData		:= aResp2[12]
		cCliente	:= aResp2[13]
	Else
		Return .f.
	EndIf


	BeginContent var xTReport
	#INCLUDE "rwmake.ch"
	#INCLUDE "topconn.ch"
	#INCLUDE "Report.ch"
	#INCLUDE "PROTHEUS.CH"
	#DEFINE  LIM_QUEBRAS 4
/*
_____________________________________________________________________________
Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦
Â¦Â¦+-----------------------------------------------------------------------+Â¦Â¦
Â¦Â¦Â¦ Funcao    Â¦ <<NOME_FUNC>>  Â¦ Autor Â¦ <<AUTOR>>      Â¦ Data Â¦ <<DATA>>  Â¦Â¦
Â¦Â¦Â¦           Â¦           Â¦       Â¦                     Â¦      Â¦           Â¦Â¦
Â¦Â¦+-----------+-----------------------------------------------------------+Â¦Â¦
Â¦Â¦Â¦ DescricÃ£o Â¦ <<TITULO_RELATORIO>>                                   Â¦Â¦
Â¦Â¦+-----------+-----------------------------------------------------------+Â¦Â¦
Â¦Â¦Â¦ Uso       Â¦ <<CLIENTE>>                                               Â¦Â¦
Â¦Â¦+-----------------------------------------------------------------------+Â¦Â¦
Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦Â¦
Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯Â¯
*/

/**************************************************************************/
User Function <<NOME_FUNC>>()
/**************************************************************************/
	Local oReport
	Local aArea  := GetArea()
	Private cNomeRelat      := '<<NOME_RELATORIO>>'
	Private cPerg           := '<<CPERG>>'
	Private cTituloRel      := '<<TITULO_RELATORIO>>'
	Private aCabGrp         := <<CAB_1GRUPO>> // Campos precisam vir na query. Se nao tiver agrupamento, passar vazio
	Private aCabGrpTxt      := <<CAB_2GRUPO_TXT>> // // legendas das sessao de cabecalho
	Private aOrdem          := <<AORDENS>>   // Campos precisam vir na query
	Private aOrdemTxt       := <<AORDEM_TXT>>  // legendas das ordens
	Private aGerarTotais    := <<AGERAR_TOTAIS>>
	Private nOrientacao     := <<NORIENTACAO>> // 1 = retrato , 2 = paisagem
	Private cFonte          := '' // em branco = default
	Private nTamanhoFonte   := 0  // 0 = default
	Private lImprimeCabecalho   := .T.
	Private lImprimeRodape      := .F.
	Private lTemAgrupamento     := Len(aCabGrp)>0

	oReport := ReportDef()

	If nOrientacao == 1
		oReport:SetPortrait()// definir como Retrato
	Else
		oReport:SetLandscape()//definir como paisagem
	EndIf

	oReport:PrintDialog()
	RestArea( aArea )

Return

/*************************************************************************/
Static Function ReportDef()
/*************************************************************************/
	Local oReport
	Local cDesc
	Local nCabs as numeric
	Local aOrd     	:= aOrdemTxt
	Private cTitulo	:= cDesc

	cDesc   := cTituloRel
	cTitulo := cTituloRel

	Static oSecaoCabecalho, oSecaoListagem

	DEFINE REPORT oReport NAME cNomeRelat TITLE cTitulo PARAMETER cPerg ACTION {|oReport| PrintReport(oReport)} DESCRIPTION cDesc

	If !Empty(cFonte)
		oReport:cFontBody:= cFonte // definir tipo da fonte do relatorio
	EndIf

	If nTamanhoFonte > 0
		oReport:nFontBody:= nTamanhoFonte // definir tamanho da fonte do relatorio
	EndIf

	oReport:lHeaderVisible := lImprimeCabecalho
	oReport:lFooterVisible := lImprimeRodape
//oReport:SetColSpace(2,.T.)//Cria o espacamento entre as colunas do relatorio

//-- Section de Informacoes
	If lTemAgrupamento
		DEFINE SECTION oSecaoCabecalho OF oReport ORDERS aOrd TITLE cTitulo PAGE BREAK
		oSecaoCabecalho:SetPageBreak(.F.)   // p/ Nao quebrar a sessÃ£o por pagina na impressÃ£o do cabecalho
	EndIf

	For nCabs := 1 to Len(aCabGrp)
		DEFINE CELL NAME "COLUNA"+StrZero(nCabs,2)	OF oSecaoCabecalho ALIAS "   " TITLE "" 	PICTURE "@!"	SIZE 25 PIXEL ALIGN LEFT
	Next

//-- Section de Informacoes
	DEFINE SECTION oSecaoListagem OF oReport ORDERS aOrd TITLE cTitulo PAGE BREAK
	oSecaoListagem:SetPageBreak(.F.)   // p/ Nao quebrar a sessÃ£o por pagina na impressÃ£o do cabecalho

	// chama a rotina para popular dicionario e informa os campos a ignorar ,
	// pois sao campos do cabecalho na sessao1
	If !LoadView('modelo',aCabGrp)
		Return NIL
	EndIf

	oSecaoListagem:SetTotalInLine(.F.) // imprime o totalizador no final de cada sessÃ£o

Return oReport
//
/*************************************************************************/
Static Function LoadView(cOrigem,aCabGrp)
/*************************************************************************/
	Local lRet := .T.
	Local nCampos as numeric

	If Select("WORK1") > 0
		WORK1->(DbCloseArea())
	Endif

	aQuery := fParseParam("<<CQUERY>>",cOrigem)

	If aQuery[1]
		cQuery := aQuery[2]
	else
		MsgAlert('Impressao Cancelada')
		Return .F.
	EndIf

	If len(aOrdem) > 0 .AND. cOrigem != 'modelo'
		cQuery  += ' ORDER BY '+aOrdem[oSecaoListagem:GetOrder()]+' '
	EndIf

	MsAguarde({|| dbUseArea(.T., "TOPCONN", TCGenQRY(,,cQuery), "WORK1", .F., .T.) },"Consultando","Aguarde...")

	DbGoTop()

	For nCampos := 1 to FCount()
		If Upper(Substr(FieldName(nCampos),1,4))=='DATA' .or. GetSx3Cache(FieldName(nCampos),"X3_TIPO")=='D'
			TcSetField('WORK1',FieldName(nCampos),'D')
		EndIf
	Next

	If cOrigem == 'modelo'
		For nCampos := 1 to FCount()
			nPos:= Ascan(aCabGrp,{|x| x == FieldName(nCampos) })
			If nPos == 0
				DEFINE CELL NAME FieldName(nCampos)	OF oSecaoListagem ALIAS "WORK1" TITLE fGetTitulo(FieldName(nCampos)) PICTURE fGetPicture(FieldName(nCampos),FieldGet(nCampos))
			EndIf
		Next

		For nCampos := 1 to Len(aCabGrp)
			If FieldPos(aCabGrp[nCampos])==0
				Alert("Campo do Grupo nao presente na tabela: "+(aCabGrp[nCampos]))
				lRet := .F.
			EndIF
		Next
	EndIf

	If Eof() .and. cOrigem != 'modelo'
		lRet := .F.
	EndIf

Return lRet

/*************************************************************************/
Static Function PrintReport(oReport)
/*************************************************************************/
	Local oSecaoCabecalho
	Local oSecaoListagem
	Local cTitulo
	Local nCampos   := 0
	Local nItem     := 0
	Local aSTotal   := Afill(Array(Fcount()),0)
	Local aGTotal   := Afill(Array(Fcount()),0)
	Local nCabs

	If lTemAgrupamento
		oSecaoCabecalho	:= oReport:Section(1)
		oSecaoListagem	:= oReport:Section(2)
	Else
		oSecaoListagem	:= oReport:Section(1)
	EndIf

	cTitulo := Iif(AllTrim(oReport:Title()) == AllTrim(cTitulo), cTitulo, oReport:Title())
	oReport:SetTitle(cTitulo)

	If lTemAgrupamento
		oSecaoCabecalho:INIT()
	EndIf

	oSecaoListagem:INIT()

	If !LoadView()
		Return .T.
	EndIf

	DbEval({|| nItem++})

	DbGoTop()

	oReport:SetMeter(nItem)

	lImprimeGrupo := lTemAgrupamento // so vai imprimir a primeira linha com o grupo se tiver o array preenchido

	While !Eof()

		oReport:IncMeter() //Incrementa o regua de Processo

		If oReport:Cancel()
			oReport:CancelPrint()
			Exit
		EndIf

		If lImprimeGrupo

			For nCabs := 1 to MIN(Len(aCabGrp),LIM_QUEBRAS)
				oSecaoCabecalho:Cell("COLUNA"+StrZero(nCabs,2)):SetValue(aCabGrpTxt[nCabs]+" "+FieldGet(FieldPos(aCabGrp[nCabs])))
			Next

			oSecaoCabecalho:Printline()
			oReport:SkipLine()
			lImprimeGrupo := .F.

		EndIf

		//oSecaoListagem:Finish()
		//oSecaoListagem:INIT()

		For nCampos := 1 to WORK1->(FCount())
			If Ascan(aGerarTotais,{|x| x == WORK1->(FieldName(nCampos)) }) > 0
				aSTotal[nCampos]+= WORK1->(FieldGet(nCampos))
				aGTotal[nCampos]+= WORK1->(FieldGet(nCampos))
			EndIf
		Next

		For nCampos := 1 to WORK1->(FCount())
			If Ascan(aCabGrp,{|x| x == WORK1->(FieldName(nCampos)) }) == 0
				oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):Show()
				oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):SetValue( WORK1->(FieldGet(nCampos)) )
			EndIf
		Next

		oSecaoListagem:Printline()

		If lTemAgrupamento

			cQuebra := ""

			For nCabs := 1 to Len(aCabGrp)
				cQuebra += FieldGet(Fieldpos(aCabGrp[nCabs]))
			Next

			WORK1->(DbSkip())

			cNovaLinha := ""
			For nCabs := 1 to Len(aCabGrp)
				cNovaLinha += FieldGet(Fieldpos(aCabGrp[nCabs]))
			Next

			If (cNovaLinha <> cQuebra) .OR. EOF()
				For nCampos := 1 to WORK1->(FCount())
					If Ascan(aCabGrp,{|x| x == WORK1->(FieldName(nCampos)) }) == 0
						If Ascan(aGerarTotais,{|x| x == WORK1->(FieldName(nCampos)) }) > 0
							oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):Show()
							oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):SetValue(aSTotal[nCampos])
						Else
							oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):Hide()
						EndIf
					EndIf
				Next

				aSTotal   := Afill(Array(Fcount()),0)
				oSecaoListagem:Printline()
				lImprimeGrupo := .T.
				oReport:ThinLine()
				oReport:SkipLine()

			EndIf
		else
			WORK1->(DbSkip())
		EndIf
	EndDo

	// Imprime total geral
	For nCampos := 1 to WORK1->(FCount())
		If Ascan(aCabGrp,{|x| x == WORK1->(FieldName(nCampos)) }) == 0
			If Ascan(aGerarTotais,{|x| x == WORK1->(FieldName(nCampos)) }) > 0
				oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):Show()
				oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):SetValue(aGTotal[nCampos])
			Else
				oSecaoListagem:Cell(WORK1->(FieldName(nCampos))):Hide()
			EndIf
		EndIf
	Next
	oSecaoListagem:Printline()

	WORK1->(DbCloseArea())

	If lTemAgrupamento
		oSecaoCabecalho:Finish()
	EndIf
	oSecaoListagem:Finish()

Return

Static Function fGetTitulo(cNome)
	Local cReturn := GetSx3Cache(cNome,"X3_TITULO")

	If Empty(AllTrim(cReturn))
		cReturn := Capital(cNome)
	EndIf

Return cReturn

Static Function fGetPicture(cNome,xConteudo)
	Local cReturn := GetSx3Cache(cNome,"X3_PICTURE")

	If Empty(Alltrim(cReturn))
		If ValType(xConteudo)=="D" .OR. Upper(Substr(cNome,1,4))=="DATA"
			cReturn := "@E 99/99/9999"
		ElseIf ValType(xConteudo)=="N"
			cReturn := "@E 99,999.99"
		Else
			cReturn := "@!"
		EndIf
	EndIf

Return cReturn

Static Function fParseParam(_cFraseSql,cOrigem)
	Local j 		:= 0
	Local cFraseSql := Alltrim(_cFraseSql)
	Local nStart  := 0
	Local nFinish := 0
	Local lParse  := .T.
	Local aPergs := {}
	Local aRet   := {}
	Local aParam := {}
	Local lImprime := .F.
	For j:=1 to Len(cFraseSQL)
		If Substr(cFraseSQL,j,2)=="<%"
			nStart ++
		EndIf
		If Substr(cFraseSQL,j,2)=="%>"
			nFinish ++
		EndIf
	Next
	If nStart > 0 .AND. nStart <> nFinish
		Alert("Tags de Parametros Incorretas")
		lParse  := .F.
	EndIf
	nStart  := 0
	nFinish := 0
	For j:=1 to Len(cFraseSQL)
		If Substr(cFraseSQL,j,2)=="<%"
			nStart := j+3
		EndIf
		If Substr(cFraseSQL,j,2)=="%>"
			nFinish := j-1
		EndIf
		IF nStart > 0 .and. nFinish > 0
			If aScan(aParam,{|x| x==Substr(cFraseSQL,nStart-1,nFinish-nStart+2)}) = 0
				AADD(aParam,Substr(cFraseSQL,nStart-1,nFinish-nStart+2))
				nTamanho := 8
				If UPPER(LEFT(aParam[Len(aParam)],4))=="DATA"
					cInicializar := dDataBase
					cF3			 := ''
					cPrompt 	 := Alltrim(Substr(aParam[Len(aParam)],5,40))
				Else
					nPos_    := Rat(' ',aParam[Len(aParam)])
					cF3      := Substr(aParam[Len(aParam)] , nPos_ + 1 , Len ( aParam[Len(aParam)]) - nPos_ )
					cRetF3   := Alltrim(Posicione('SXB',1,PAD(cF3,6)+'4','XB_CONTEM'))

					If At(">",cRetF3) > 0
						cRetF3 := Alltrim(Substr(cRetF3,At(">",cRetF3)+1,40))
					EndIf

					// se for no formato C99

					if Substr(cF3,1,1)=="C" .AND. Substr(cF3,2,1)$"0123456789" .AND. Substr(cF3,3,1)$"0123456789"
						nTamanho := Val(Substr(cF3,2,2))
						cPrompt := StrTran(aParam[Len(aParam)],cF3,'')
						cF3 := ''
					else

						nTamanho := GetSx3Cache(cRetF3,'X3_TAMANHO')

						// Se voltar vazio
						If ValType(nTamanho)== 'U'
							nTamanho := nFinish - nStart  //Len((&cRetF3))
							cPrompt := StrTran(aParam[Len(aParam)],cF3,'')
							cF3      := ""

						else
							If Empty(Posicione('SXB',1,cF3,'XB_ALIAS'))
								cF3 := ''
								cPrompt := aParam[Len(aParam)]
							Else
								cPrompt := StrTran(aParam[Len(aParam)],cF3,'')
							EndIf
						endif
					endif

					cInicializar := Space(nTamanho)

				EndIf
				aAdd( aPergs ,{1,cPrompt,cInicializar,iif(UPPER(LEFT(aParam[Len(aParam)],4))=="DATA","@E 99/99/99","@!"),'.T.',cF3,'.T.',nTamanho*5,.F.})
			EndIf
			nStart  := 0
			nFinish := 0
		EndIf
	Next
	IF len(aPergs)>0
		If cOrigem != 'modelo'
			lImprime := ParamBox(aPergs,"Parametros",aRet,,,,,,,'TRESTR15B',.T.,.T.)
		Else
			lImprime := .T.
			aRet := Afill(Array(Len(aPergs)),'')
		EndIf
		For j := 1 to Len(aRet)
			If UPPER(LEFT(aParam[j],4))=="DATA"
				cFraseSQL := StrTran(cFraseSQL,"<%"+aParam[j]+"%>","'"+ Iif(Empty(aRet[j]),' ',DTOS(aRet[j])) +"'")
			Else
				cFraseSQL := StrTran(cFraseSQL,"<%"+aParam[j]+"%>","'"+ Iif(Empty(aRet[j]),' ',Alltrim(aRet[j])) +"'")
			EndIf
		Next
	EndIf
Return {lImprime .OR. (nStart+nFinish==0), cFraseSQL}


// INICIO DO PARSE

	EndContent
	xTReport := STRTRAN(xTReport,'<<CQUERY>>'			,Alltrim(StrTran(StrTran(StrTran(cQuery,chr(10),' '),chr(13),' '),'"',"'")))
	xTReport := STRTRAN(xTReport,'<<NOME_RELATORIO>>'	,Alltrim(cNomeRelat))
	xTReport := STRTRAN(xTReport,'<<CPERG>>'			,Alltrim(cPerg))
	xTReport := STRTRAN(xTReport,'<<TITULO_RELATORIO>>'	,Alltrim(cTituloRel))
	xTReport := STRTRAN(xTReport,'<<CAB_1GRUPO>>'		,Alltrim(aCabGrp))
	xTReport := STRTRAN(xTReport,'<<CAB_2GRUPO_TXT>>'	,Alltrim(aCabGrpTxt))
	xTReport := STRTRAN(xTReport,'<<AORDENS>>'			,Alltrim(aOrdem))
	xTReport := STRTRAN(xTReport,'<<AORDEM_TXT>>'		,Alltrim(aOrdemTxt))
	xTReport := STRTRAN(xTReport,'<<AGERAR_TOTAIS>>'	,Alltrim(aGerarTotais))
	xTReport := STRTRAN(xTReport,'<<NOME_FUNC>>'		,Alltrim(cNomeFunc))
	xTReport := STRTRAN(xTReport,'<<NORIENTACAO>>'		,nOrientacao)
	xTReport := STRTRAN(xTReport,'<<AUTOR>>'		    ,Alltrim(cAutor))
	xTReport := STRTRAN(xTReport,'<<DATA>>'				,Alltrim(DTOC(cData)))
	xTReport := STRTRAN(xTReport,'<<CLIENTE>>'			,Alltrim(cCliente))

	oResult := TMultiget():Create(oDlg1,{|u|if(Pcount()>0,xTReport:=u,xTReport)},160,001,588,170,oFont2,,,,,.T.,,,,,,,,,,,.T.)

Return nil

Static Function fParseParam(_cFraseSql,cOrigem)
	Local j 		:= 0
	Local cFraseSql := Alltrim(_cFraseSql)
	Local nStart  := 0
	Local nFinish := 0
	Local lParse  := .T.
	Local aPergs := {}
	Local aRet   := {}
	Local aParam := {}
	Local lImprime := .F.
	For j:=1 to Len(cFraseSQL)
		If Substr(cFraseSQL,j,2)=="<%"
			nStart ++
		EndIf
		If Substr(cFraseSQL,j,2)=="%>"
			nFinish ++
		EndIf
	Next
	If nStart > 0 .AND. nStart <> nFinish
		Alert("Tags de Parametros Incorretas")
		lParse  := .F.
	EndIf
	nStart  := 0
	nFinish := 0
	For j:=1 to Len(cFraseSQL)
		If Substr(cFraseSQL,j,2)=="<%"
			nStart := j+3
		EndIf
		If Substr(cFraseSQL,j,2)=="%>"
			nFinish := j-1
		EndIf
		IF nStart > 0 .and. nFinish > 0
			If aScan(aParam,{|x| x==Substr(cFraseSQL,nStart-1,nFinish-nStart+2)}) = 0
				AADD(aParam,Substr(cFraseSQL,nStart-1,nFinish-nStart+2))
				nTamanho := 8
				If UPPER(LEFT(aParam[Len(aParam)],4))=="DATA"
					cInicializar := dDataBase
					cF3			 := ''
					cPrompt 	 := Alltrim(Substr(aParam[Len(aParam)],5,40))
				Else
					nPos_    := Rat(' ',aParam[Len(aParam)])
					cF3      := Substr(aParam[Len(aParam)] , nPos_ + 1 , Len ( aParam[Len(aParam)]) - nPos_ )
					cRetF3   := Alltrim(Posicione('SXB',1,PAD(cF3,6)+'4','XB_CONTEM'))

					If At(">",cRetF3) > 0
						cRetF3 := Alltrim(Substr(cRetF3,At(">",cRetF3)+1,40))
					EndIf

					// se for no formato C99

					if Substr(cF3,1,1)=="C" .AND. Substr(cF3,2,1)$"0123456789" .AND. Substr(cF3,3,1)$"0123456789"
						nTamanho := Val(Substr(cF3,2,2))
						cPrompt := StrTran(aParam[Len(aParam)],cF3,'')
						cF3 := ''
					else

						nTamanho := GetSx3Cache(cRetF3,'X3_TAMANHO')

						// Se voltar vazio
						If ValType(nTamanho)== 'U'
							nTamanho := nFinish - nStart  //Len((&cRetF3))
							cPrompt := StrTran(aParam[Len(aParam)],cF3,'')
							cF3      := ""

						else
							If Empty(Posicione('SXB',1,cF3,'XB_ALIAS'))
								cF3 := ''
								cPrompt := aParam[Len(aParam)]
							Else
								cPrompt := StrTran(aParam[Len(aParam)],cF3,'')
							EndIf
						endif
					endif

					cInicializar := Space(nTamanho)

				EndIf
				aAdd( aPergs ,{1,cPrompt,cInicializar,iif(UPPER(LEFT(aParam[Len(aParam)],4))=="DATA","@E 99/99/99","@!"),'.T.',cF3,'.T.',nTamanho*5,.F.})
			EndIf
			nStart  := 0
			nFinish := 0
		EndIf
	Next
	IF len(aPergs)>0
		If cOrigem != 'modelo'
			lImprime := ParamBox(aPergs,"Parametros",aRet,,,,,,,'TRESTR15B',.T.,.T.)
		Else
			lImprime := .T.
			aRet := Afill(Array(Len(aPergs)),'')
		EndIf
		For j := 1 to Len(aRet)
			If UPPER(LEFT(aParam[j],4))=="DATA"
				cFraseSQL := StrTran(cFraseSQL,"<%"+aParam[j]+"%>","'"+ Iif(Empty(aRet[j]),' ',DTOS(aRet[j])) +"'")
			Else
				cFraseSQL := StrTran(cFraseSQL,"<%"+aParam[j]+"%>","'"+ Iif(Empty(aRet[j]),' ',Alltrim(aRet[j])) +"'")
			EndIf
		Next
	EndIf
Return {lImprime .OR. (nStart+nFinish==0), cFraseSQL}

Static Function fExecQry(cQueryTxt)
	TCQuery cQueryTxt New Alias "WORK1"
Return

static FUNCTION NoAcento(cString)
	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÝÉÝÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÝÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ"
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"

	If !Empty(cString)
		For nX:= 1 To Len(cString)
			cChar:=SubStr(cString, nX, 1)
			IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
				nY:= At(cChar,cAgudo)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cCircu)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cTrema)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cCrase)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
				EndIf
				nY:= At(cChar,cTio)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
				EndIf
				nY:= At(cChar,cCecid)
				If nY > 0
					cString := StrTran(cString,cChar,SubStr("cC",nY,1))
				EndIf
			Endif
		Next
	Endif

	If cMaior$ cString
		cString := strTran( cString, cMaior, "" )
	EndIf
	If cMenor$ cString
		cString := strTran( cString, cMenor, "" )
	EndIf

	If '>'$ cString
		cString := strTran( cString, '>', "" )
	EndIf

	If '<'$ cString
		cString := strTran( cString, '<', "" )
	EndIf

	If '&'$ cString
		cString := strTran( cString, '&', " e " )
	EndIf

	cString := StrTran( cString, CRLF, " " )

Return cString

Static Function fExpressao(cFilter)
	Local oDlg
	Local oExpr
	Local oCampo
	Local oBtnOp
	Local oBtnE
	Local oBTNou
	Local oBTNa
	Local oBtnExp
	Local oBtn
	Local oTxtFil
	Local oOper
	Local oMatch
	Local oConf
	Local aStrOp
	Local cExpr
	Local cCampo    := ""
	Local cOper     := ""
	Local cTxtFil   := ""
	Local cExpFil   := ""
	Local cRet      := ""
	Local cExprfil  := ""
	Local aCampo    := DbStruct()
	Local aCpo      := {}
	Local nMatch    := 0
	Local lConfirma := .f.
	Local lOk       := .F.
	Local x
	Local oValBool
	Local aValBool
	Local cValBool

	aStrOp := { "Igual a",; //'Equal to'
	"Diferente de",; //'Different from'
	"Menor que",; //'Less than'
	"Menor ou igual a",; //'Less than or equal to'
	"Maior que","Maior ou igual a",; //'Greater than'###'Greater than or equal to'
	"Cont�m a express�o","N�o cont�m a express�o",; //'Contain the expression'###'Do not contain'
	"Est� contido em",; //'Is contained in'
	"N�o est� contido em" } //'Not contained into'

	cFilter := ""

	For x := 1 To Len(aCampo)
		Aadd(aCpo,aCampo[x,1])
	Next

	DEFINE MSDIALOG oDlg FROM 020, 010 TO 205, 435 TITLE 'Construtor de Expressoes' PIXEL //'Expression constructor'

	DEFINE SBUTTON oConf FROM 076, 142 TYPE 1 DISABLE OF oDlg;
		ACTION ((If(lOk := (nMatch==0),nil,.F.),;
		If(lOk,lOk := fExpressOk(@cExpFil),nil),If(lOk,lConfirma:=.T.,nil), If(lOk,oDlg:End(),nil)))

		DEFINE SBUTTON FROM 076, 174 TYPE 2 ENABLE OF oDlg ACTION (oDlg:End())

		@ 006, 140 SAY "Expressao" SIZE 055,007 OF oDlg PIXEL //'Expression:'
		@ 014, 140 GET oExpr VAR cExpr SIZE 070, 009 OF oDlg Picture "@" PIXEL FONT oDlg:oFont

		aValBool := {".T.",".F."}
		@ 014, 140 COMBOBOX oValBool VAR cValBool ITEMS aValBool SIZE 070,009 OF oDlg PIXEL
		oValBool:Hide()

		@ 014, 005 COMBOBOX oCampo VAR cCampo ITEMS aCpo SIZE 060, 035 OF oDlg PIXEL ;
			ON CHANGE ( If(aCampo[oCampo:nAt][2]=="L",(oExpr:Disable(),oExpr:Hide(),oValBool:Enable(),oValBool:Show()),;
			(oValBool:nAt:=1,oValBool:Disable(),oValBool:Hide(),oExpr:Enable(),oExpr:Show(),BuildGet(oExpr,@cExpr,aCampo,oCampo,oDlg,,oOper:nAt))))

		cExpr := fCalcField(oCampo:nAt,aCampo)
		cOper := aStrOp[1]

		@ 014, 070 COMBOBOX oOper VAR cOper ITEMS aStrOp SIZE 065, 035 OF oDlg PIXEL;
			VALID If(aCampo[oCampo:nAt][2]=="L" .And. oOper:nAt<>1,((MsgStop("Operador Invalido","Erro"),.F.)),.T.); //"Operador invalido!"
		ON CHANGE BuildGet(oExpr,@cExpr,aCampo,oCampo,oDlg,,oOper:nAt)

		@ 006, 005 SAY "Campos" SIZE 039,007 OF oDlg PIXEL //'Fields:'
		@ 006, 070 SAY "Operadores" SIZE 039,007 OF oDlg PIXEL //'Operators:'

		@ 046, 005  SAY "Filtrar"  SIZE 53, 7 OF oDlg PIXEL //'Filter:'

		@ 031, 005 BUTTON oBtnA PROMPT "Adicionar" SIZE 040, 011 OF oDlg PIXEL //'&Add'
		oBtnA:bAction := {|lBool| lBool:=(aCampo[oCampo:nAt][2]=="L"), If(lBool,(cExpr:=cValBool,lBool:=(oOper:nAt==1)),lBool:=.T.),;
			If(!lBool,MsgStop("Operador Invalido","Erro"),(oConf:SetEnable(.t.),;
				cTxtFil := fExpToTexto(cTxtFil,Trim(cCampo),;
				cOper,cExpr,.t.,@cExpFil,aCampo,oCampo:nAt,oOper:nAt,cValBool),;
				cExpr := TamCampo(oCampo:nAt,aCampo),;
				BuildGet(oExpr,@cExpr,aCampo,oCampo,oDlg,,oOper:nAt),;
				oTxtFil:Refresh(),oBtnE:Enable(),oBtnOp:Disable(),;
				oBtnOu:Enable(),oBtne:Refresh(),oBtnOu:Refresh(),;
				oBtnExp:Disable(),oBtna:Disable(),oBtna:Refresh()))}

			oBtnA:oFont := oDlg:oFont

			@ 031, 050 BUTTON oBtn PROMPT "Limpa Filtro" SIZE 040, 011 OF oDlg PIXEL; //'&Clear Filter'
			ACTION (oConf:SetEnable(.t.),cTxtFil := "",;
				cExpFil := "",nMatch := 0,oTxtFil:Refresh(),;
				oBtnA:Enable(),oBtnE:Disable(),oBtnOU:Disable(),;
				oMatch:Disable(),oBtnOp:Enable(),oConf:Refresh(),oBtnExp:Enable(),oBtnExp:Refresh()) ; oBtn:oFont := oDlg:oFont

			@ 031, 095 BUTTON oBtnExp PROMPT "Expressao" SIZE 040, 011 OF oDlg PIXEL ; //'&Expression'
			ACTION (lRet:=ExprFiltro(@cTxtFil,@cExpFil),oTxtFil:Refresh(),;
				If(lRet,oBtnOp:Disable(),oBtnOp:Enable()),If(lRet,oBtnExp:Disable(),oBtnExp:Enable()) ,;
					If(lRet,oBtna:Disable(),oBtna:Enable()),;
						If(lRet,oBtnE:Enable(),oBtnE:Disable()),;
							If(lRet,oConf:SetEnable(.t.),oConf:SetEnable(.F.)),;
								If(lRet,oBtnOu:Enable(),oBtnOu:Disable())) ;oBtnExp:oFont := oDlg:oFont

								@ 053,005 GET oTxtFil VAR cTxtFil SIZE 205, 020 OF oDlg PIXEL MEMO COLOR CLR_BLACK,CLR_HGRAY READONLY

								oTxtFil:bRClicked := {||AlwaysTrue()}

								@ 025, 180 BUTTON oBtnOp PROMPT "("  SIZE 013,011 OF oDlg PIXEL ACTION (If(nMatch==0,oMatch:Enable(),nil),nMatch++,cTxtFil+= " ( ",cExpFil+="(",oTxtFil:Refresh()) ; oBtnOp:oFont := oDlg:oFont
								@ 025, 193 BUTTON oMatch PROMPT ")" 	SIZE 013,011 OF oDlg PIXEL ACTION (nMatch--,cTxtFil+= " ) ",cExpFil+=")",If(nMatch==0,oMatch:Disable(),nil),oTxtFil:Refresh()) ; oMatch:oFont := oDlg:oFont
								@ 038, 180 BUTTON oBtne	PROMPT " and " SIZE 013,011 OF oDlg PIXEL;
									ACTION (cTxtFil+=" and ",cExpFil += ".and.",;
									oTxtFil:Refresh(),oBtne:Disable(),oBtnou:Disable(),;
									oBtnExp:Enable(),oBtnA:Enable(),oBtne:Refresh(),oBtnou:Refresh(),;
									oBtnA:Refresh(),oBtnOp:Enable())

								oBtne:oFont := oDlg:oFont

								@ 038, 193 BUTTON oBtnOU PROMPT " or "	SIZE 013,011 OF oDlg PIXEL;
									ACTION (cTxtFil+=" or ",cExpFil += ".or.",oTxtFil:Refresh(),;
									oBtne:Disable(),oBtnou:Disable(),oBtnExp:Enable(),oBtnA:Enable(),;
									oBtne:Refresh(),oBtnou:Refresh(),oBtna:Refresh(),oBtnOp:Enable())

								oBtnou:oFont := oDlg:oFont

								oMatch:Disable()
								oBtnE:Disable()
								oBtnOu:Disable()

								ACTIVATE MSDIALOG oDlg CENTERED

								If lConfirma
									If cExpFil # Nil
										cRet := cExpFil
									EndIf
									Return cRet
								EndIf

								Return Pad(cExprfil,255)

//Teste generico de expressao
Static Function fExpressOk(cExp,cMsg)
	Local lOk	:= .T.
	Local lVal  := NIL
	Local oErro

	oErro := ErrorBlock({|e| fShowErr(e,cMsg)})
	BEGIN SEQUENCE
		If !Empty(cExp)
			lVal := &(cExp)
			lOk := (lVal <> NIL)
		Endif
	END SEQUENCE
	ErrorBlock(oErro)

Return lOk

//Calculo do Tamanho do Campo
Static Function fCalcField(nAt,aCampo)
	Local cRet := ""
	If !Empty(nAt)
		If aCampo[nAt,2] == "C"
			cRet := Space(aCampo[nAt,3])
		ElseIf aCampo[nAt,2] == "M"
			cRet := Space(255)
		ElseIf aCampo[nAt,2] == "N"
			cRet := 0
		ElseIf aCampo[nAt,2] == "D"
			cRet := CTOD("  /  /  ")
		EndIf
	EndIf
Return cRet


// --------------------------------------------------------------------------------
//Tela generica de Expressao
Static Function DispExpr(cFilter)
	Local oDlg
	Local oExpr
	Local oCampo
	Local oBtnOp
	Local oBtnE
	Local oBTNou
	Local oBTNa
	Local oBtnExp
	Local oBtn
	Local oTxtFil
	Local oOper
	Local oMatch
	Local oConf
	Local aStrOp
	Local cExpr
	Local cCampo    := ""
	Local cOper     := ""
	Local cTxtFil   := ""
	Local cExpFil   := ""
	Local cRet      := ""
	Local cExprfil  := ""
	Local aCampo    := DbStruct()
	Local aCpo      := {}
	Local nMatch    := 0
	Local lConfirma := .f.
	Local lOk       := .F.
	Local x
	Local oValBool
	Local aValBool
	Local cValBool

	aStrOp := { "Igual a",; //'Equal to'
	"Diferente de",; //'Different from'
	"Menos que",; //'Less than'
	"Menor ou igual a",; //'Less than or equal to'
	"Maior que","Maior ou igual a",; //'Greater than'###'Greater than or equal to'
	"Contem Expressao","Nao contem",; //'Contain the expression'###'Do not contain'
	"Est� contido",; //'Is contained in'
	"N�o est� contido" } //'Not contained into'

	cFilter := ""

	For x := 1 To Len(aCampo)
		Aadd(aCpo,aCampo[x,1])
	Next

	DEFINE MSDIALOG oDlg FROM 020, 010 TO 205, 435 TITLE 'Construtor de Express�es' PIXEL //'Expression constructor'

	DEFINE SBUTTON oConf FROM 076, 142 TYPE 1 DISABLE OF oDlg;
		ACTION ((If(lOk := (nMatch==0),nil,.F.),;
		If(lOk,lOk := ExprOK(@cExpFil),nil),If(lOk,lConfirma:=.T.,nil), If(lOk,oDlg:End(),nil)))

		DEFINE SBUTTON FROM 076, 174 TYPE 2 ENABLE OF oDlg ACTION (oDlg:End())

		@ 006, 140 SAY 'Express�o' SIZE 055,007 OF oDlg PIXEL //'Expression:'
		@ 014, 140 GET oExpr VAR cExpr SIZE 070, 009 OF oDlg Picture "@" PIXEL FONT oDlg:oFont

		aValBool := {".T.",".F."}
		@ 014, 140 COMBOBOX oValBool VAR cValBool ITEMS aValBool SIZE 070,009 OF oDlg PIXEL
		oValBool:Hide()

		@ 014, 005 COMBOBOX oCampo VAR cCampo ITEMS aCpo SIZE 060, 035 OF oDlg PIXEL ;
			ON CHANGE ( If(aCampo[oCampo:nAt][2]=="L",(oExpr:Disable(),oExpr:Hide(),oValBool:Enable(),oValBool:Show()),;
			(oValBool:nAt:=1,oValBool:Disable(),oValBool:Hide(),oExpr:Enable(),oExpr:Show(),BuildGet(oExpr,@cExpr,aCampo,oCampo,oDlg,,oOper:nAt))))

		cExpr := TamCampo(oCampo:nAt,aCampo)
		cOper := aStrOp[1]

		@ 014, 070 COMBOBOX oOper VAR cOper ITEMS aStrOp SIZE 065, 035 OF oDlg PIXEL;
			VALID If(aCampo[oCampo:nAt][2]=="L" .And. oOper:nAt<>1,((MsgStop("Operador Invalido","Erro"),.F.)),.T.); //"Operador invalido!"
		ON CHANGE BuildGet(oExpr,@cExpr,aCampo,oCampo,oDlg,,oOper:nAt)

		@ 006, 005 SAY "Campos" SIZE 039,007 OF oDlg PIXEL //'Fields:'
		@ 006, 070 SAY "Operadores" SIZE 039,007 OF oDlg PIXEL //'Operators:'

		@ 046, 005  SAY "Filtros"  SIZE 53, 7 OF oDlg PIXEL //'Filter:'

		@ 031, 005 BUTTON oBtnA PROMPT 'Adicionar' SIZE 040, 011 OF oDlg PIXEL //'&Add'
		oBtnA:bAction := {|lBool| lBool:=(aCampo[oCampo:nAt][2]=="L"), If(lBool,(cExpr:=cValBool,lBool:=(oOper:nAt==1)),lBool:=.T.),;
			If(!lBool,MsgStop("Operador Invalido","Erro"),(oConf:SetEnable(.t.),;
				cTxtFil := ExpToTexto(cTxtFil,Trim(cCampo),;
				cOper,cExpr,.t.,@cExpFil,aCampo,oCampo:nAt,oOper:nAt,cValBool),;
				cExpr := TamCampo(oCampo:nAt,aCampo),;
				BuildGet(oExpr,@cExpr,aCampo,oCampo,oDlg,,oOper:nAt),;
				oTxtFil:Refresh(),oBtnE:Enable(),oBtnOp:Disable(),;
				oBtnOu:Enable(),oBtne:Refresh(),oBtnOu:Refresh(),;
				oBtnExp:Disable(),oBtna:Disable(),oBtna:Refresh()))}

			oBtnA:oFont := oDlg:oFont

			@ 031, 050 BUTTON oBtn PROMPT "Limpa Filtro" SIZE 040, 011 OF oDlg PIXEL; //'&Clear Filter'
			ACTION (oConf:SetEnable(.t.),cTxtFil := "",;
				cExpFil := "",nMatch := 0,oTxtFil:Refresh(),;
				oBtnA:Enable(),oBtnE:Disable(),oBtnOU:Disable(),;
				oMatch:Disable(),oBtnOp:Enable(),oConf:Refresh(),oBtnExp:Enable(),oBtnExp:Refresh()) ; oBtn:oFont := oDlg:oFont

			@ 031, 095 BUTTON oBtnExp PROMPT "Expressao" SIZE 040, 011 OF oDlg PIXEL ; //'&Expression'
			ACTION (lRet:=ExprFiltro(@cTxtFil,@cExpFil),oTxtFil:Refresh(),;
				If(lRet,oBtnOp:Disable(),oBtnOp:Enable()),If(lRet,oBtnExp:Disable(),oBtnExp:Enable()) ,;
					If(lRet,oBtna:Disable(),oBtna:Enable()),;
						If(lRet,oBtnE:Enable(),oBtnE:Disable()),;
							If(lRet,oConf:SetEnable(.t.),oConf:SetEnable(.F.)),;
								If(lRet,oBtnOu:Enable(),oBtnOu:Disable())) ;oBtnExp:oFont := oDlg:oFont

								@ 053,005 GET oTxtFil VAR cTxtFil SIZE 205, 020 OF oDlg PIXEL MEMO COLOR CLR_BLACK,CLR_HGRAY READONLY

								oTxtFil:bRClicked := {||AlwaysTrue()}

								@ 025, 180 BUTTON oBtnOp PROMPT "("  SIZE 013,011 OF oDlg PIXEL ACTION (If(nMatch==0,oMatch:Enable(),nil),nMatch++,cTxtFil+= " ( ",cExpFil+="(",oTxtFil:Refresh()) ; oBtnOp:oFont := oDlg:oFont
								@ 025, 193 BUTTON oMatch PROMPT ")" 	SIZE 013,011 OF oDlg PIXEL ACTION (nMatch--,cTxtFil+= " ) ",cExpFil+=")",If(nMatch==0,oMatch:Disable(),nil),oTxtFil:Refresh()) ; oMatch:oFont := oDlg:oFont
								@ 038, 180 BUTTON oBtne	PROMPT " and " SIZE 013,011 OF oDlg PIXEL;
									ACTION (cTxtFil+=" and ",cExpFil += ".and.",;
									oTxtFil:Refresh(),oBtne:Disable(),oBtnou:Disable(),;
									oBtnExp:Enable(),oBtnA:Enable(),oBtne:Refresh(),oBtnou:Refresh(),;
									oBtnA:Refresh(),oBtnOp:Enable())

								oBtne:oFont := oDlg:oFont

								@ 038, 193 BUTTON oBtnOU PROMPT " or "	SIZE 013,011 OF oDlg PIXEL;
									ACTION (cTxtFil+=" or ",cExpFil += ".or.",oTxtFil:Refresh(),;
									oBtne:Disable(),oBtnou:Disable(),oBtnExp:Enable(),oBtnA:Enable(),;
									oBtne:Refresh(),oBtnou:Refresh(),oBtna:Refresh(),oBtnOp:Enable())

								oBtnou:oFont := oDlg:oFont

								oMatch:Disable()
								oBtnE:Disable()
								oBtnOu:Disable()

								ACTIVATE MSDIALOG oDlg CENTERED

								If lConfirma
									If cExpFil # Nil
										cRet := cExpFil
									EndIf
									Return cRet
								EndIf

								Return Pad(cExprfil,255)

// --------------------------------------------------------------------------------
//Teste generico de expressao
Static Function ExprOK(cExp,cMsg)
	Local lOk	:= .T.
	Local lVal  := NIL
	Local oErro

	oErro := ErrorBlock({|e| fShowErr(e,cMsg)})
	BEGIN SEQUENCE
		If !Empty(cExp)
			lVal := &(cExp)
			lOk := (lVal <> NIL)
		Endif
	END SEQUENCE
	ErrorBlock(oErro)

Return lOk

Static Function fShowErr(e, cMsg)
	FWAlertError('Erro encontrado na f�rmula ' + If(!Empty(cMsg),cMsg,"") , e:description )
	Break
Return nil


// --------------------------------------------------------------------------------
//Atualiza o Get 
Static Function BuildGet(oExpr,cExpr,aCampo,oCampo,oDlg,lFirst,nOpr)
	Local aOper		:= { "=","!=","<","<=",">",">=","..","!.","$","!x"}
	Local cPicture	:= "@"

	cExpr := TamCampo(oCampo:nAt,aCampo)
	DEFAULT lFirst := .t.

	If aCampo[oCampo:nAT,2] == "N"
		cPicture := "@E "+Replicate("9",aCampo[oCampo:nAT,3])
		If aCampo[oCampo:nAT,4] > 0
			cPicture := Subs(cPicture,1,Len(cPicture)-(aCampo[oCampo:nAt,4]+1))
			cPicture += "."+Replicate("9",aCampo[oCampo:nAT,4])
		EndIf
	ElseIf aCampo[oCampo:nAT,2] == "C"
		cPicture := "@K"
	EndIf

	If aCampo[oCampo:nAt,2] == "D"
		cPicture := "@D"
	EndIf

	If nOpr != Nil
		If aOper[nOpr] $ "$|!x"
			cExpr := Space(60)
			cPicture := "@S23"
		EndIf
	EndIf

	SetFocus(oExpr:hWnd)
	oExpr:oGet:Picture := cPicture
	oExpr:oGet:Pos     := 0
	oExpr:oGet:Assign()
	oExpr:oGet:UpdateBuffer()
	oExpr:Refresh()

// Executando a segunda vez para for�ar a Picture do GET.
	If lFirst
		BuildGet(oExpr,cExpr,aCampo,oCampo,oDlg,.f.,nOpr)
	EndIf

Return cPicture

// --------------------------------------------------------------------------------
//Calculo do Tamanho do Campo
Static Function TamCampo(nAt,aCampo)
	Local cRet := ""
	If !Empty(nAt)
		If aCampo[nAt,2] == "C"
			cRet := Space(aCampo[nAt,3])
		ElseIf aCampo[nAt,2] == "M"
			cRet := Space(255)
		ElseIf aCampo[nAt,2] == "N"
			cRet := 0
		ElseIf aCampo[nAt,2] == "D"
			cRet := CTOD("  /  /  ")
		EndIf
	EndIf
Return cRet

// --------------------------------------------------------------------------------
//Expressao do Filtro
Static Function ExprFiltro(cTxtFil,cExpFil)

	Local oDlg, oBtn
	Local cExpr    := Space(255)
	Local lProcess := .F.

	DEFINE MSDIALOG oDlg TITLE 'Express�o' FROM 000,000 TO 100,500 OF oExplorer:oDlg PIXEL //'Expression'

	@ 010,010 MSGET oExpr VAR cExpr SIZE 230,010 OF oDlg PIXEL

	@ 030,010 TO 030,240 OF oDlg PIXEL

	@ 035,010 BUTTON oBtn PROMPT 'Adicionar' SIZE 040,010 PIXEL; //'&Add'
	ACTION (If(ExprOK(cExpr),(lProcess := .t.,oDlg:End()),Nil))

	@ 035,055 BUTTON oBtn PROMPT 'Cancelar' SIZE 040,010 PIXEL; //'&Cancel'
	ACTION oDlg:End()

	ACTIVATE MSDIALOG oDlg CENTERED

	If lProcess

		cTxtFil += Trim(cExpr)
		cExpFil += Trim(cExpr)

		// Retorno correto para o Enable/Disable dos botoes.
		If Empty(cExpr)
			lProcess:= .F.
		EndIf

	EndIf

Return lProcess

// --------------------------------------------------------------------------------
// Constroi o Texto da Expressao
Static Function ExpToTexto(cTxtFil,cCampo,cOper,xExpr,lAnd,cExpFil,aCampo,nCpo,nOper,cValBool)

	Local cChar := OemToAnsi(CHR(39))
	Local cType := ValType(xExpr)
	Local aOper := { "==","!=","<","<=",">",">=","..","!.","$","!x"}

	If ( aOper[nOper] == "!." .Or. aOper[nOper] == "!x" .Or. aOper[nOper]	== ".." )
		cTxtFil += cCampo+" "+cOper+" "+If(cType=="C",cChar,"")+AllTrim(cValToChar(xExpr))+If(cType=="C",cChar,"")
	Else
		If aCampo[nCpo][2]=="L"
			cChar := ""
		End
		cTxtFil += cCampo+" "+cOper+" "+If(cType=="C",cChar,"")+cValToChar(xExpr)+If(cType=="C",cChar,"")
	EndIf

	If cType == "C"
		If aOper[nOper] == "!."    //  Nao Contem
			cExpFil += '!('+'"'+AllTrim(cValToChar(xExpr))+'"'+' $ '+AllTrim(aCampo[nCpo,1])+')'   // Inverte Posicoes
		ElseIf aOper[nOper] == "!x"   // Nao esta contido
			cExpFil += '!('+AllTrim(aCampo[nCpo,1])+" $ " + '"'+AllTrim(cValToChar(xExpr))+'")'
		ElseIf aOper[nOper]	== ".."  // Contem a Expressao
			cExpFil += '"'+AllTrim(cValToChar(xExpr))+'"'+" $ "+AllTrim(aCampo[nCpo,1])   // Inverte Posicoes
		Else
			cExpFil += aCampo[nCpo,1] +aOper[nOper]+" "
			If aCampo[nCpo][2]=="L" .And. nOper==1
				cExpFil += cValToChar(xExpr)
			Else
				cExpFil += '"'+cValToChar(xExpr)+'"'
			EndIf
		EndIf
	ElseIf cType == "D"
		// Nao Mexer, deixar dToS pois e'a FLAG Para Limpeza do Filtro
		//
		cExpFil += "Dtos("+aCampo[nCpo,1]+") "+aOper[nOper]+' "'
		cExpFil += Dtos(CTOD(cValToChar(xExpr),"DEFAULT"))+'"'
	Else
		cExpFil += aCampo[nCpo,1]+" "+aOper[nOper]+" "
		cExpFil += cValToChar(xExpr)
	EndIf

Return cTxtFil

	If select("TRB") <> 0
		TRB->(DbCloseArea())
	EndIf

Static Function SelCampos(_cAlias)
	Local aStruct   := {}
	Local aStruct2  := {}
	Local aReturn   := {}
	Local i 		:= 0
	Local lOk 		:= .F.
	Local aHead1    := {}
	Private cTMP1   := GetNextAlias()
	Private cEdit1  := Space(40)
	Private lMkDesm := .F.

	AAdd(aStruct, {"TR_OK"     , 'C', 02, 0})
	AAdd(aStruct, {"Campo"     , "C", 10, 0})
	AAdd(aStruct, {"Descricao" , "C", 40, 0})

	aAdd(aHead1, {"TR_OK"		, "!"			})
	aAdd(aHead1, {"Campo"		, "Campo"		})
	aAdd(aHead1, {"Descricao"	, "Descricao"	})

	oTable := FwTemporaryTable():New(cTMP1, aStruct)
	oTable:AddIndex('01', {'Descricao'} )
	oTable:Create()

	aStruct2 := (_cAlias)->(DbStruct())

	For i := 1 to Len(aStruct2)
		Reclock(cTMP1,.T.)
		Replace Campo With aStruct2[i,1]
		Replace Descricao With GetSx3Cache(aStruct2[i,1],"X3_TITULO")
		MsUnlock()
	Next

	cMarca := GetMark()

	dbSelectArea(cTMP1)
	DbGoTop()

	DEFINE MSDIALOG _oDlg TITLE OemtoAnsi("Selecionar Campos") FROM C(178),C(181) TO C(560),C(765) PIXEL

	@ C(175),C(004) Button OemtoAnsi("Marca/Desmarca todos") Size C(070),C(012) ACTION MkDmk() PIXEL OF _oDlg
	@ C(175),C(235) Button OemtoAnsi("OK")      Size C(025),C(012) ACTION {|| lOk := .T., _oDlg:End()} PIXEL OF _oDlg
	@ C(175),C(260) Button OemtoAnsi("Cancela") Size C(025),C(012) ACTION {|| lOk := .F., _oDlg:End()} PIXEL OF _oDlg
	@ C(177),C(080) Say "Texto:" Size C(012),C(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ C(175),C(100) Get oEdit1 Var cEdit1 Size C(80),C(010) COLOR CLR_BLACK  PIXEL OF _oDlg
	@ C(175),C(210) Button OemtoAnsi("Procurar") Size C(025),C(012) ACTION Procura(cTMP1,cEdit1,"campo","descricao") PIXEL OF _oDlg
	@ C(000),C(000) TO C(170),C(292) BROWSE cTMP1 MARK "TR_OK" FIELDS aHead1 Object oMark
	oMark:oBrowse:lHasmark    := .t.
	oMark:oBrowse:lCanAllmark := .t.
	oMark:oBrowse:bAllMark    := {|| Inverte()}

	ACTIVATE MSDIALOG _oDlg CENTERED ON INIT  Inverte()

	If lOk
		DbGoTop()
		Do While !Eof()
			If IsMark("TR_OK",cMarca)
				AADD(aReturn,{Alltrim(Campo),(_cAlias)->(FieldPos(Alltrim((cTMP1)->Campo)))})
			EndIf
			DbSkip()
		EndDo

	EndIf

	oTable:DELETE()

Return aReturn

Static Function Procura(cAlias,cBuscar,cCampo1,cCampo2)
	If !Alltrim(cBuscar) == ''
		DbSelectArea(cAlias)
		DbSkip()
		Do While !Eof()
			If  Upper(Alltrim(cBuscar)) $ Upper(Alltrim((cAlias)->&(cCampo1))) + " " + Upper(Alltrim((cAlias)->&(cCampo2)))
				Return
			Endif
			DbSkip()
		Enddo
	Endif
Return

Static Function Inverte()
	Local nRecno:= (cTMP1)->(Recno())

	DbSelectArea(cTMP1)
	DbGoTop()
	Do While !Eof()
		RecLock(cTMP1, .f.)
		Replace TR_OK	with IIF(TR_OK == cMarca, Space(2), cMarca)
		MsUnlock()
		DbSkip()
	EndDo

	(cTMP1)->(DbGoTo(nRecno))
	oMark:oBrowse:Refresh()

Return

/**************************************************************************/
Static Function MkDmk()
/**************************************************************************/
	Local nRecno:= (cTMP1)->(Recno())

	DbSelectArea(cTMP1)
	DbGoTop()
	If lMkDesm == .f.
		Do While !Eof()
			RecLock(cTMP1, .f.)
			Replace TR_OK	with cMarca
			MsUnlock()
			DbSkip()
		EndDo
		lMkDesm := .t.
	Else
		Do While !Eof()
			RecLock(cTMP1, .f.)
			Replace TR_OK	with Space(2)
			MsUnlock()
			DbSkip()
		EndDo
		lMkDesm := .f.
	Endif
	(cTMP1)->(DbGoTo(nRecno))
	oMark:oBrowse:Refresh()

Return

Static Function fGeraXml()
	Local k
	Local aLinha := {}
	Local nProc  := 1
	DbGoTop()
	Do While !EOF()

		MsProcTxt("Aguarde: "+Alltrim(str(ROUND(nProc/nLinhas*100,0))))

		aLinha := {}

		If lQuery

			For k:=1 To FCount()
				If ValType(FieldGet(k))=="C"
					AADD(aLinha,NoAcento(FieldGet(k)))
				Else
					AADD(aLinha,FieldGet(k))
				Endif
			Next

		Else

			For k:= 1 to Len(aSelCampos)

				If ValType(FieldGet(aSelCampos[k,2]))=="C"
					AADD(aLinha,NoAcento(FieldGet(aSelCampos[k,2])))
				Else
					AADD(aLinha,FieldGet(aSelCampos[k,2]))
				Endif

			Next

		EndIf
		oExcel:AddRow("Dados","Planilha",aLinha)
		DbSkip()
	EndDo

Return nil

Static Function fGeraExcel()
	Local j:= 0

	oExcel := FWMSEXCEL():New()
	oExcel:AddworkSheet("Dados")
	oExcel:AddTable ("Dados","Planilha")
	DbSelectArea(_cMyAlias)
	nFields := FCount()
	for j:=1 to nFields
		If lQuery
			oExcel:AddColumn("Dados","Planilha",FieldName(j),1,1)
		ElseIf ASCAN(aSelCampos,{|x| x[1] == FieldName(j)}) > 0
			oExcel:AddColumn("Dados","Planilha",FieldName(j),1,1)
		EndIf
	next
	DbSelectArea(_cMyAlias)
	DbGoTop()
	nLinhas := 1
	DbEval({|| nLinhas++})
	MsAguarde({|| fGeraXML() },"Exportando Dados ","Aguarde... "+STR(nLinhas,8,0)+" linhas ")
	DbGoTop()
	oExcel:Activate()

Return nil

Static Function fGeraCSV()
	Local j     := 0
	Local cCab  := ""
	Local nProc := 1

	DbSelectArea(_cMyAlias)
	nFields := FCount()
	for j:=1 to nFields
		If lQuery
			cCab += FieldName(j) + ";"
		ElseIf ASCAN(aSelCampos,{|x| x[1] == FieldName(j)}) > 0
			cCab += FieldName(j) + ";"
		EndIf
	next

	DbSelectArea(_cMyAlias)
	DbGoTop()

	nLinhas := 1

	DbEval({|| nLinhas++})

	IF nLinhas >= 1048575
		MsgInfo("Atencao! Este arquivo ultrapassa o PageSizee para abertura no Excel 1.048.575 linhas","Atencao")
		Return .f.
	EndIf

	DbGoTop()

	oFileCSV:= FWFileWriter():New(_cPasta + cBarra + _cArquivo)

	If !oFileCSV:create()
		MsgInfo("Erro ao criar arquivo "+_cPasta + cBarra + _cArquivo,"Alerta")
		Return .f.
	EndIf

	oFileCSV:Write(cCab + CRLF)

	Do While !Eof()
		nProc++

		MsProcTxt(Alltrim(str(ROUND(nProc/nLinhas*100,0)))+"% conclu�do.")

		cDado := ""

		For j:= 1 to Len(aSelCampos)
			xDado := FieldGet(aSelCampos[j,2])
			If ValType(xDado) == "N"
				xDado := StrTran(cValToChar(xDado),".",",")
			EndIf
			cDado += cValToChar(xDado)+";"
		Next

		oFileCSV:Write(cDado + CRLF)

		DbSkip()

	EndDo
	DbGoTop()
	oFileCSV:Close()

Return nil
Static Function fGeraDTC()
	DbSelectArea(_cMyAlias)
	COPY TO "\cadzic\"+_cArquivo
	MsAguarde({|| CpyS2T( "\cadzic\"+_cArquivo, _cPasta, .F. ) },"Copiando DTC","Aguarde...")
	FERASE("\cadzic\"+_cArquivo)
Return nil

User Function CADZIC()
	Local lTemTabela := .F.
	Local lTemCampo  := .F.
	Private aRotAdic:={}

	chkfile("ZIC",.F.)

	lTemTabela := ( Select("ZIC") > 0 )

	If lTemTabela
		lTemCampo := ZIC->(FieldPos("ZIC_SQL")) > 0
	EndIf

	If lTemTabela .AND. lTemCampo
		aadd(aRotAdic,{ 'Executar'   ,'u_ExecSQL()' , 0, 6})
		SetKey(VK_F9, { || u_ExecSql() })
		AxCadastro("ZIC","Cadastro de Consultas SQL",,Iif(FWIsAdmin( __cUserID ),".T.",".F."),aRotAdic)
	Else
		cMsg := "Para utilizar a rotina � necess�rio criar tabela: "
		cMsg += "ZIC - Cadastro de Consultas SQL" + CRLF
		cMsg += "ZIC_FILIAL (CHAR("+STRZERO(LEN(xFilial("SD2")),2,0)+")) => Filial" + CRLF
		cMsg += "ZIC_CODIGO (CHAR(6)) => Codigo" + CRLF
		cMsg += "ZIC_DESCR (CHAR(200)) => Descricao" + CRLF
		cMsg += "ZIC_SQL (MEMO) => Script SQL" + CRLF
		FWAlertError(cMsg, "Aten��o")
	EndIf

Return nil

User Function ExecSql()
	u_CFGQSQL(ZIC->ZIC_SQL)
Return nil

Static Function fPerm(cFrase)
	Local lReturn := .T.
	Local j

	For j:= 1 to Len(aBloqueios)

		lReturn := lReturn .AND. ! ( aBloqueios[j][1] $ UPPER(cFrase) )

	Next

Return lReturn

Static Function fBuscaPerm()
	Local cLista
	Local aLista  := {}
	Local nXi     := 0
	Local cArqCfg := "lista_perm.txt"

	cLista := "SD1;Item NF Entrada" + CRLF
	cLista += "SD2;Item NF Saida" + CRLF
	cLista += "SD3;Requisicoes" + CRLF
	cLista += "SF1;Cab NF Entrada" + CRLF
	cLista += "SF2;Cab NF Saida" + CRLF
	cLista += "SF3;Cab Livro Fiscal" + CRLF
	cLista += "SFT;Item Livro Fiscal" + CRLF
	cLista += "CDA;Compl. Livro " + CRLF
	cLista += "SE1;Titulo a Receber " + CRLF
	cLista += "SE2;Titulo a Pagar" + CRLF
	cLista += "SE3;Comissoes" + CRLF
	cLista += "SE4;Cond. Pagto." + CRLF
	cLista += "SE5;Mov. Bancario" + CRLF
	cLista += "SEF;Naturezas" + CRLF
	cLista += "SA1;Clientes" + CRLF
	cLista += "SA2;Fornecedores" + CRLF
	cLista += "SA3;Vendedores" + CRLF
	cLista += "SA4;Transporadora" + CRLF
	cLista += "SB1;Produtos" + CRLF

	If Empty(MemoRead(cArqCfg))
		MemoWrite(cArqCfg,cLista)
	Else
		cLista := MemoRead(cArqCfg)
	EndIf

	For nXi := 1 To MLCount(cLista,100)
		aLinha1:= StrToKARR(MemoLine(cLista,100,nXi),";")
		AADD(aLista,{aLinha1[1],aLinha1[2]})
	Next nXi

Return aLista

Static Function fBloqueios()
	Local cLista
	Local aLista  := {}
	Local nXi     := 0
	Local cArqCfg := "lista_bloq.txt"

	cLista := "SRA010;Funcion�rios" + CRLF
	cLista += "SRD010;Folha" + CRLF

	If Empty(MemoRead(cArqCfg))
		MemoWrite(cArqCfg,cLista)
	Else
		cLista := MemoRead(cArqCfg)
	EndIf

	For nXi := 1 To MLCount(cLista,100)
		aLinha1:= StrToKARR(MemoLine(cLista,100,nXi),";")
		AADD(aLista,{aLinha1[1],aLinha1[2]})
	Next nXi

Return aLista

Static Function SelTab(aLista)
	Local aStruct   := {}
	Local cReturn   := " "
	Local i 		:= 0
	Local lOk 		:= .F.
	Local aHead1    := {}
	Private cTMP2   := GetNextAlias()
	Private cEdit1  := Space(40)
	Private lMkDesm := .F.

	AAdd(aStruct, {"Tabela"    , "C", 03, 0})
	AAdd(aStruct, {"Descricao" , "C", 40, 0})

	aAdd(aHead1, {"Tabela"		, "Tabela"		})
	aAdd(aHead1, {"Descricao"	, "Descricao"	})

	oTable := FwTemporaryTable():New(cTMP2, aStruct)
	oTable:AddIndex('01', {'Descricao'} )
	oTable:Create()

	For i := 1 to Len(aLista)
		Reclock(cTMP2,.T.)
		Replace Tabela 	  With aLista[i,1]
		Replace Descricao With aLista[i,2]
		MsUnlock()
	Next

	dbSelectArea(cTMP2)
	DbGoTop()

	DEFINE MSDIALOG _oDlg TITLE OemtoAnsi("Selecionar Tabela") FROM C(178),C(181) TO C(560),C(765) PIXEL

	@ C(175),C(235) Button OemtoAnsi("OK")      Size C(025),C(012) ACTION {|| lOk := .T., _oDlg:End()} PIXEL OF _oDlg
	@ C(175),C(260) Button OemtoAnsi("Cancela") Size C(025),C(012) ACTION {|| lOk := .F., _oDlg:End()} PIXEL OF _oDlg
	@ C(177),C(080) Say "Texto:" Size C(012),C(008) COLOR CLR_BLACK PIXEL OF _oDlg
	@ C(175),C(100) Get oEdit1 Var cEdit1 Size C(80),C(010) COLOR CLR_BLACK  PIXEL OF _oDlg
	@ C(175),C(210) Button OemtoAnsi("Procurar") Size C(025),C(012) ACTION Procura(cTMP2,cEdit1,"tabela","descricao") PIXEL OF _oDlg
	@ C(000),C(000) TO C(170),C(292) BROWSE cTMP2 FIELDS aHead1 Object oMark
	ACTIVATE MSDIALOG _oDlg CENTERED

	If lOk
		cReturn := Alltrim(Tabela)
	EndIf

	oTable:DELETE()

Return cReturn

User Function ConvCert()
	Local _cArquivo := space(100)
	Local _cArqCA   := space(100)
	Local _cArqCert := space(100)
	Local _cArqKey  := space(100)
	Local _cSenha   := space(100)
	Local cRet      := space(100)

	aPergs  := {}
	aRet    := {}

	_cArquivo := "\cert_cte\20382889.pfx"
	_cArqCA   := "\cert_cte\20382889_ca"
	_cArqCert := "\cert_cte\20382889_cert"
	_cArqKey  := "\cert_cte\20382889_key"
	_cSenha   := "50759273"


	aAdd( aPergs ,{6,"Arquivo PFX"   ,_cArquivo,"",,"", 80 ,.T.,"Arquivos .* |*.*","C:\",GETF_LOCALHARD})
	aadd( aPergs ,{1,"Arquivo CA "   ,_cArqCA  ,"","","",".T.",80,.F.}) 	//
	aadd( aPergs ,{1,"Arquivo Cert " ,_cArqCert,"","","",".T.",80,.F.}) 	//
	aadd( aPergs ,{1,"Arquivo Key "  ,_cArqKey ,"","","",".T.",80,.F.}) 	//
	aadd( aPergs ,{1,"senha "        ,_cSenha  ,"","","",".T.",80,.F.}) 	//

	If ParamBox(aPergs ,"Converte PFX para PEM",aRet,/*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.F./*lCanSave*/,.F./*lUserSave*/ )
		PFX2PEM2(alltrim(aRet[1]), alltrim(aRet[5]), alltrim(aRet[2]), alltrim(aRet[3]), alltrim(aRet[4]), cRet )
	EndIf

Return nil

Static Function PFX2PEM2(cArquivo, cPsw, cArqCA, cArqCERT, cArqKEY, cRet )
	Local cError := ""
	Default cArquivo := ""
	Default cPsw := ""
	Default cArqCA := ""
	Default cArqCERT := ""
	Default cArqKEY := ""
	Default cRet := ""

	cArquivo := AllTrim( cArquivo )
	cPsw := AllTrim( cPsw )
	cArqCA := AllTrim( cArqCA )
	cArqCERT := AllTrim( cArqCERT )
	cArqKEY := AllTrim( cArqKEY )

	//Garante que os arquivos ser�o gerados com a extens�o correta
	If Right( Upper( cArqCA ), 4 ) != ".PEM"
		cArqCA += ".pem"
	Endif
	If Right( Upper( cArqCERT ), 4 ) != ".PEM"
		cArqCERT += ".pem"
	Endif
	If Right( Upper( cArqKEY ), 4 ) != ".PEM"
		cArqKEY += ".pem"
	Endif

	//Gera o arquivo de Certificado de Autoriza��o
	If PFXCA2PEM( cArquivo, cArqCA, @cError, cPsw )
		//Gera o arquivo de Certificado de Cliente
		If PFXCert2PEM( cArquivo, cArqCERT, @cError, cPsw )
			//Gera o arquivo de Chave Privada
			If ! PFXKey2PEM( cArquivo, cArqKEY, @cError, cPsw )
				cRet := OemToAnsi("Erro ao extrair a chave privada. ") + cError //
			Endif
		Else
			cRet := OemToAnsi("Erro ao extrair o Certificado de Cliente. ") + cError //
		Endif
	Else
		cRet := OemToAnsi("Erro ao extrair o Certificado de Autoriza��o. ") + cError //
	Endif

	If !Empty(alltrim(cRet))
		FwAlertError(cRet,"Erro!")
	Else
		MsgInfo("Convertido com sucesso","INFO")
	EndIf

Return .T.

	WSRESTFUL QSQL DESCRIPTION "Web Services REST Protheus [QSQL] - Consultas SQL"
		WSDATA Query As String
		WSDATA Page   As Integer
		WSDATA PageSize  As Integer
		WSMETHOD GET DESCRIPTION "Consulta dados na Base" ;
			WSSYNTAX "/{Query, Page, PageSize}"

	END WSRESTFUL

WSMETHOD GET WSRECEIVE Query, Page, PageSize WSSERVICE QSQL
	Local aArea      := GetArea()
	Local Query      := Self:Query
	Local Page       := Self:Page
	Local PageSize   := Self:PageSize
	Local cAlias     := "WORK1"
	Local j 	     := 0
	Local oResponse  := JsonObject():New()
	Local lRet       := .T.
	Local cLabel     := ""
	Default Page     := 1
	Default PageSize := 100
	Default Query   := " "

	//// http://192.168.60.45:8012/rest/api/oauth2/v1/token?grant_type=password&username=usuario&password=senha

	If GetRemoteType() < 0
		RPCSetType(3)
		RPCSetEnv("01","01","","","","",{"SB1","",""})
	EndIf

	::SetContentType("application/json")

	aRet := fRunQuery(Query, cAlias)

	If !Eof() .AND. aRet[1]

		COUNT TO nTotalRegistros

		DbGoTop()

		nTotalPaginas := NoRound(nTotalRegistros / PageSize, 0)
		nTotalPaginas += Iif(nTotalRegistros % PageSize != 0, 1, 0)

		If Page != 1
			&(cAlias)->(DbSkip(( Page - 1) * PageSize))
		EndIf

		oResponse["objects"] := {}
		oResponse["labels"]  := {}

		oJsonResult := JsonObject():New()
		oJsonResult["total"]        := nTotalRegistros
		oJsonResult["current_page"] := Page
		oJsonResult["total_page"]   := nTotalPaginas
		oJsonResult["page_size"]    := PageSize
		oResponse["meta"] 	        := oJsonResult

		nRec := 0

		Do While !Eof()

			If nRec == 0 
				
				oJsonObj := JsonObject():New()

				For j:= 1 to FCount()

					If FieldName(j) == "R_E_C_N_O_"

						oJsonObj[FieldName(j)] := 'RECNO'

					ElseIf FieldName(j) == "R_E_C_D_E_L_"

						oJsonObj[FieldName(j)] := 'RECDEL'

					Else 

						cLabel := FWhttpEncode(GetSx3Cache(FieldName(j),"X3_TITULO"))
					
						If Empty(cLabel) .OR. cLabel == 'null'
							cLabel := FieldName(j)
						EndIf
					
						oJsonObj[FieldName(j)]   := cLabel
					
					EndIf 
				Next

				aAdd(oResponse["labels"], oJsonObj)

			EndIf 

			nRec++

			If nRec <= PageSize

				oJsonObj := JsonObject():New()

				For j:= 1 to FCount()
					oJsonObj[FieldName(j)]   := cValToChar(FieldGet(j))
				Next

				aAdd(oResponse["objects"], oJsonObj)

			Else

				Exit

			EndIf

			DbSkip()

		EndDo

		Self:SetResponse(oResponse:toJSON())

	Else

		If aRet[1]
			SetRestFault(500, "Sem Dados.")
			lRet := .F.
		Else
			SetRestFault(500, aRet[2])
			lRet := .F.
		EndIf

	EndIf

	&(cAlias)->(DbCloseArea())

	RestArea(aArea)

Return lRet

Static Function fRunQuery(Query,cAlias)
	Local aRet   := {.T.,'Sucesso'}
	Local oError := ErrorBlock({|e| aRet[1] := .F., aRet[2] := "Mensagem de Erro: " +chr(10)+ e:Description })

	Begin Sequence
		
		If !("UPDATE") $ UPPER(Query) .AND. !("INSERT") $ UPPER(Query) .AND.  !("DELETE")  $ UPPER(Query)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,Query),cAlias,.T.,.T.)
		else 
			nRes := TCSQLEXEC(Query)
			If nRes <> 0 
				aRet   := {.F.,'Falha na atualiza��o'}
			EndIf 
		EndIf 

		Return aRet
	End Sequence

	ErrorBlock(oError)

Return aRet

User Function QSQLWEB()
	FwCallApp("qsqlweb")
Return nil 

User Function LimpaXML(cTexto)
Local cReturn := ''
Local cLib    := '0123456789abcdefghijklmnopqrstuvxywz<>?/()\.,:=+-*^$#@![;] '
Local j       := 0 

	For j := 1 to Len(cTexto)

		cChar := Substr(cTexto,j,1)

		If cChar $ cLib .OR. cChar $ Upper(cLib) .OR. cChar == '"' .OR. cChar == "'"
			cReturn += cChar
		EndIf 

	Next 

Return cReturn
