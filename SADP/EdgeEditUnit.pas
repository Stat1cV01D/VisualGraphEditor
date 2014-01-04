unit EdgeEditUnit;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, StdCtrls, ExtCtrls;

type
	TEdgeEditForm = class(TForm)
		LabeledEdit1: TLabeledEdit;
		Button1: TButton;
		procedure Button1Click(Sender: TObject);
        procedure FormShow(Sender: TObject);
        procedure LabeledEdit1KeyPress(Sender: TObject; var Key: Char);
	private
		{ Private declarations }
	public
		{ Public declarations }
		Weight: Integer;
	end;

var
	EdgeEditForm: TEdgeEditForm;

implementation

{$R *.dfm}

procedure TEdgeEditForm.Button1Click(Sender: TObject);
begin
	Weight := StrToInt(LabeledEdit1.Text);
	ModalResult := mrOK;
end;

procedure TEdgeEditForm.FormShow(Sender: TObject);
begin
	LabeledEdit1.Text := IntToStr(Weight);
end;

procedure TEdgeEditForm.LabeledEdit1KeyPress(Sender: TObject; var Key: Char);
begin
	case Key of
    	#13,#10: Button1Click(Sender);
    end;
end;

end.
