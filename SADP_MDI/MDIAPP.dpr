program Mdiapp;

{$R *.dres}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  SysUtils,
  Main in 'Main.pas' {CoreForm},
  about in 'about.pas' {AboutBox},
  Algo in '..\SADP\Algo.pas',
  EdgeEditUnit in '..\SADP\EdgeEditUnit.pas' {EdgeEditForm},
  MainFrm in '..\SADP\MainFrm.pas' {MDIChild},
  FibonacciHeap in 'FibonacciHeap.pas',
  AllItemsUnit in '..\SADP\AllItemsUnit.pas' {AllItemsForm},
  DataStoreUnit in '..\SADP\DataStoreUnit.pas';

{$R *.RES}

var
	i: Integer;
begin
	for I := 0 to 10 do
    	if 1 < 2 then
        ;

  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TCoreForm, CoreForm);
  Application.CreateForm(TAboutBox, AboutBox);
  if ParamCount <> 0 then
  begin
  	if ExtractFileExt(ParamStr(1)) = '.sv0' then
  		CoreForm.CreateMDIChild(ParamStr(1));
  end
  else
  	Application.CreateForm(TMDIChild, MDIChild_DONT_USE_IT);
  Application.CreateForm(TAllItemsForm, AllItemsForm);
  //Application.CreateForm(TEdgeEditForm, EdgeEditForm);
  Application.Run;
end.
