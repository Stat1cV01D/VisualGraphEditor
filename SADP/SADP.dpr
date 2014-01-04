program SADP;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  DataStoreUnit in 'DataStoreUnit.pas',
  Algo in 'Algo.pas',
  ToolTips in 'ToolTips.pas',
  EdgeEditUnit in 'EdgeEditUnit.pas' {EdgeEditForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  //Application.CreateForm(TEdgeEditForm, EdgeEditForm);
  Application.Run;
end.
