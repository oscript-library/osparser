﻿
// Плагин для проверки использования переменных и параметров.
// Отслеживаются следующие ситуации:
// - значение переменной не читается после присваивания (объявление тоже считается присваиванием)
// - значение параметра-значения не читается после присваивания
// - к параметру-ссылке нет обращений
//
// примечания:
// Анализ в целом выполняется поверхностно и возможны ложные срабатывания.

// todo: проверять два присваивания одной переменной подряд

Var Nodes;
Var Result;

Var Vars, Params;
Var IsWhileStmtCond, CondVarsList;

Procedure Init(BSLParser) Export
	Nodes = BSLParser.Nodes();
	Result = New Array;
	Vars = New Map;
	Params = New Map;
	IsWhileStmtCond = False;
	CondVarsList = New Array;
EndProcedure // Init() 

Function Result() Export
	Return StrConcat(Result, Chars.LF);
EndFunction // Result()

Function Interface() Export
	Var Interface;
	Interface = New Array;
	Interface.Add("AfterVisitAssignStmt");
	Interface.Add("VisitDesigExpr");
	Interface.Add("VisitFuncDecl");
	Interface.Add("VisitProcDecl");
	Interface.Add("AfterVisitFuncDecl");
	Interface.Add("AfterVisitProcDecl");
	Interface.Add("VisitWhileStmt");
	Interface.Add("AfterVisitWhileStmt");
	Interface.Add("VisitStatements");
	Return Interface;
EndFunction // Interface() 

Procedure VisitWhileStmt(WhileStmt, Stack, Counters) Export
	IsWhileStmtCond = True;
	CondVarsList.Clear();
EndProcedure // VisitWhileStmt() 

Procedure VisitStatements(Statements, Stack, Counters) Export
	IsWhileStmtCond = False;	
EndProcedure // VisitStatements()

Procedure AfterVisitWhileStmt(WhileStmt, Stack, Counters) Export
	For Each Object In CondVarsList Do
		If Vars[Object] <> Undefined Then
			Vars[Object] = "Get";
		ElsIf Params[Object] <> Undefined Then
			Params[Object] = "Get";	
		EndIf;
	EndDo;
EndProcedure // AfterVisitWhileStmt()

Procedure AfterVisitAssignStmt(AssignStmt, Stack, Counters) Export
	Var Object, Operation;
	Operation = "Set"; 
	If AssignStmt.Left.Select.Count() > 0 Then
		Return;
	EndIf;
	Object = AssignStmt.Left.Object; 
	If Vars[Object] <> Undefined Then
		Vars[Object] = Operation;
	ElsIf Params[Object] <> Undefined Then
		Params[Object] = Operation;
	EndIf; 
EndProcedure // AfterVisitAssignStmt()

Procedure VisitDesigExpr(DesigExpr, Stack, Counters) Export
	Var Object;
	If Stack.Parent.Type = Nodes.AssignStmt
		And Stack.Parent.Left = DesigExpr Then
		Return;
	EndIf;
	Object = DesigExpr.Object;
	If Vars[Object] <> Undefined Then
		Vars[Object] = "Get";
	ElsIf Params[Object] <> Undefined Then
		Params[Object] = "Get";	
	EndIf;
	If IsWhileStmtCond Then
		CondVarsList.Add(Object);
	EndIf; 
EndProcedure // VisitDesigExpr()

Procedure VisitFuncDecl(FuncDecl, Stack, Counters) Export
	VisitMethodDecl(FuncDecl, Stack, Counters);
EndProcedure // VisitFuncDecl()

Procedure VisitProcDecl(ProcDecl, Stack, Counters) Export
	VisitMethodDecl(ProcDecl, Stack, Counters);
EndProcedure // VisitProcDecl()

Procedure AfterVisitFuncDecl(FuncDecl, Stack, Counters) Export
	AfterVisitMethodDecl(FuncDecl, Stack, Counters, "Функция");
EndProcedure // AfterVisitFuncDecl()

Procedure AfterVisitProcDecl(FuncDecl, Stack, Counters) Export
	AfterVisitMethodDecl(FuncDecl, Stack, Counters, "Процедура");
EndProcedure // AfterVisitProcDecl()

Procedure VisitMethodDecl(MethodDecl, Stack, Counters)
	Vars = New Map;
	Params = New Map;		
	For Each Param In MethodDecl.Object.Params Do
		Params[Param] = "Nil";
	EndDo;
	For Each VarLocListDecl In MethodDecl.Decls Do
		For Each VarLoc In VarLocListDecl.List Do
			Vars[VarLoc] = "Set";
		EndDo;  
	EndDo;
	For Each VarLoc In MethodDecl.Auto Do
		Vars[VarLoc] = "Set";
	EndDo;
EndProcedure // VisitMethodDecl()

Procedure AfterVisitMethodDecl(FuncDecl, Stack, Counters, Method)
	For Each Item In Vars Do
		If Item.Value <> "Get" Then
			Result.Add(StrTemplate("%1 `%2()` содержит неиспользуемую переменную `%3`", Method, FuncDecl.Object.Name, Item.Key.Name));
		EndIf; 
	EndDo;
	For Each Item In Params Do
		If Item.Value = "Nil" Or Item.Value = "Set" And Item.Key.ByVal Then
			Result.Add(StrTemplate("%1 `%2()` содержит неиспользуемый параметр `%3`", Method, FuncDecl.Object.Name, Item.Key.Name));
		EndIf; 
	EndDo;
EndProcedure // AfterVisitMethodDecl()