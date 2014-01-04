unit MAIN;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, Menus,
	StdCtrls, Dialogs, Buttons, Messages, ExtCtrls, ComCtrls, StdActns,
	ActnList, ToolWin, ImgList, TB2MRU, MainFRM, TB2Dock, TB2Item, TB2Toolbar;

type
	TCoreForm = class(TForm)
		MainMenu1: TMainMenu;
		File1: TMenuItem;
		FileNewItem: TMenuItem;
		FileOpenItem: TMenuItem;
		FileCloseItem: TMenuItem;
		Window1: TMenuItem;
		Help1: TMenuItem;
		N1: TMenuItem;
		FileExitItem: TMenuItem;
		WindowCascadeItem: TMenuItem;
		WindowTileItem: TMenuItem;
		WindowArrangeItem: TMenuItem;
		HelpAboutItem: TMenuItem;
		OpenDialog: TOpenDialog;
		FileSaveItem: TMenuItem;
		FileSaveAsItem: TMenuItem;
		WindowMinimizeItem: TMenuItem;
		StatusBar: TStatusBar;
		ActionList1: TActionList;
		FileNew1: TAction;
		FileSave1: TAction;
		FileExit1: TAction;
		FileOpen1: TAction;
		FileSaveAs1: TAction;
		WindowCascade1: TWindowCascade;
		WindowTileHorizontal1: TWindowTileHorizontal;
		WindowArrangeAll1: TWindowArrange;
		WindowMinimizeAll1: TWindowMinimizeAll;
		HelpAbout1: TAction;
		FileClose1: TWindowClose;
		WindowTileVertical1: TWindowTileVertical;
		WindowTileItem2: TMenuItem;
		ToolBar2: TToolBar;
		ToolButton1: TToolButton;
		ToolButton2: TToolButton;
		ToolButton3: TToolButton;
		ToolButton9: TToolButton;
		ToolButton8: TToolButton;
		ToolButton10: TToolButton;
		ToolButton11: TToolButton;
		ImageList1: TImageList;
    	TBMRUList1: TTBMRUList;
    TBToolbar1: TTBToolbar;
    TBSubmenuItem2: TTBSubmenuItem;
    TBMRUListItem1: TTBMRUListItem;
		procedure FileNew1Execute(Sender: TObject);
		procedure FileOpen1Execute(Sender: TObject);
		procedure HelpAbout1Execute(Sender: TObject);
		procedure FileExit1Execute(Sender: TObject);
    	procedure ToolButton2Click(Sender: TObject);
    	procedure FileSave1Execute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TBMRUList1Click(Sender: TObject; const Filename: string);
	private
		{ Private declarations }
        function GetMDIChild: TMDIChild;
	public
		{ Public declarations }
		procedure CreateMDIChild(const FileName: string; ForceCreateEmpty: Boolean = False);
		procedure MDIChildChanged();
        property ChildWnd: TMDIChild read GetMDIChild;
	end;

var
	CoreForm: TCoreForm;

implementation

{$R *.dfm}

uses about, IniFiles;

function TCoreForm.GetMDIChild: TMDIChild;
begin
    Result := ActiveMDIChild as TMDIChild;
end;

procedure TCoreForm.CreateMDIChild(const FileName: string; ForceCreateEmpty: Boolean = False);
begin
	{ create a new MDI child window }
	if FileExists(FileName) or ForceCreateEmpty then
    begin
		with TMDIChild.Create(Application) do
        begin
			Caption := FileName;
			LoadFile(FileName);
        end;
    end;
end;

procedure TCoreForm.FileNew1Execute(Sender: TObject);
begin
	CreateMDIChild('NONAME' + IntToStr(MDIChildCount + 1), True);
end;

procedure TCoreForm.FileOpen1Execute(Sender: TObject);
begin
	if OpenDialog.Execute then
		CreateMDIChild(OpenDialog.FileName);
end;

procedure TCoreForm.FileSave1Execute(Sender: TObject);
begin
	(ActiveMDIChild as TMDIChild).SaveDocument();
end;

procedure TCoreForm.FormClose(Sender: TObject; var Action: TCloseAction);
Var INI: TIniFile;
begin
    INI := TIniFile.Create('Settings.ini');
    TBMRUList1.SaveToIni(INI, 'MRU');
    INI.Free;
end;

procedure TCoreForm.FormCreate(Sender: TObject);
Var INI: TIniFile;
begin
    INI := TIniFile.Create('Settings.ini');
	TBMRUList1.LoadFromIni(INI, 'MRU');
    INI.Free;
end;

procedure TCoreForm.HelpAbout1Execute(Sender: TObject);
begin
	AboutBox.ShowModal;
end;

procedure TCoreForm.FileExit1Execute(Sender: TObject);
begin
	Close;
end;

procedure TCoreForm.MDIChildChanged();
begin
	ToolButton2.Enabled := (ActiveMDIChild as TMDIChild).ChangesMade;
end;

procedure TCoreForm.TBMRUList1Click(Sender: TObject; const Filename: string);
begin
	CreateMDIChild(FileName);
end;

procedure TCoreForm.ToolButton2Click(Sender: TObject);
begin
	FileSave1Execute(Sender);
end;

end.
