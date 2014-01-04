unit AllItemsUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DataStoreUnit, ExtActns, ActnList, Grids, ValEdit, ListActns;

type
  TAllItemsForm = class(TForm)
    Grid: TStringGrid;
    procedure GridSetEditText(Sender: TObject; ACol, ARow: Integer; const _Value: string);
    procedure GridGetEditMask(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    PrevSelItem: Integer;
  public
    { Public declarations }
    procedure UpdateData(DataStore: TDataStore);
  end;

var
  AllItemsForm: TAllItemsForm;

implementation
uses MainFrm;

{$R *.dfm}
procedure TAllItemsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	(Grid.Rows[PrevSelItem].Objects[0] as TConnection).Flag := mfNormal;
    (Parent as TMDIChild).RepaintMainImage;	
end;

procedure TAllItemsForm.GridGetEditMask(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
	Value := '#####;0;_';
end;

procedure TAllItemsForm.GridSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
    if (PrevSelItem <> -1) and Assigned(Grid.Rows[PrevSelItem].Objects[0]) then    
    	(Grid.Rows[PrevSelItem].Objects[0] as TConnection).Flag := mfNormal;

	PrevSelItem := ARow;
    if Assigned(Grid.Rows[PrevSelItem].Objects[0]) then 
    begin
    	(Grid.Rows[PrevSelItem].Objects[0] as TConnection).Flag := mfMarkedBold;
        (Parent as TMDIChild).RepaintMainImage;
    end;
end;

procedure TAllItemsForm.GridSetEditText(Sender: TObject; ACol, ARow: Integer; const _Value: string);
begin
    try
        with (Grid.Rows[ARow].Objects[0] as TConnection) do
            case ACol of
                1: Weight := StrToInt(_Value);
                2: Flow := StrToInt(_Value);
            end;
      	(Parent as TMDIChild).RepaintMainImage;
    except

    end;
end;

procedure TAllItemsForm.UpdateData(DataStore: TDataStore);
var
  	I: Integer;
    Lbl: String;
begin
	for I := 0 to Grid.ColCount -1 do
    begin
    	Grid.Cols[i].Clear;
    end;
    
    PrevSelItem := -1;

	with DataStore.Connections do
    begin
        with Grid do
        begin
            RowCount := Count;
            Cells[0, 0] := 'Ребро';
            Cells[1, 0] := 'Вес';
            Cells[2, 0] := 'Поток';
        end;

		for I := 0 to Count-1 do
        begin
        	with Items[i] do
            begin
                if (Direction = ndK2V) then
                    Lbl := IntToStr(Key.ID) + '->' + IntToStr(Value.ID)
                else if (Direction = ndV2K) then
                	Lbl := IntToStr(Value.ID) + '->' + IntToStr(Key.ID)
                else if (Direction = (ndK2V or ndV2K)) then
                	Lbl := IntToStr(Key.ID) + '<->' + IntToStr(Value.ID)
                else
					continue;

                with Grid do
                begin
                    Cells[0, i+1] := Lbl;
                    Cells[1, i+1] := IntToStr(Weight);
                    Cells[2, i+1] := IntToStr(Flow);
                    Objects[0, i+1] := Items[i];
                end;
            end;
        end;
        PrevSelItem := 1;
		Items[0].Flag := mfMarkedBold;
        (Parent as TMDIChild).RepaintMainImage;
    end;
end;

end.
