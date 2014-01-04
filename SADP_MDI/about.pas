unit about;

interface

uses Windows, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, Tabs, ComCtrls;

type
  TAboutBox = class(TForm)
    TabSet1: TTabSet;
    Panel2: TPanel;
    RichEdit1: TRichEdit;
    Panel1: TPanel;
    AboutPanel: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    OKButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure TabSet1Change(Sender: TObject; NewTab: Integer; var AllowChange: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.dfm}

procedure TAboutBox.FormCreate(Sender: TObject);
Var RS: TResourceStream;
begin
	RS := TResourceStream.Create(hInstance, 'MANUAL', RT_RCDATA);
	RichEdit1.Lines.LoadFromStream(RS);
    RS.Free;
end;

procedure TAboutBox.TabSet1Change(Sender: TObject; NewTab: Integer; var AllowChange: Boolean);
begin
	Panel1.Visible := NewTab = 0;
    Panel2.Visible := NewTab = 1;
end;

end.
 
