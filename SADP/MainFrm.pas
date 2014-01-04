unit MainFrm;
{$DEFINE UseGDIPlus}

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, ImgList,
	ComCtrls, ToolWin, ExtCtrls, Generics.Collections, DataStoreUnit, pngimage, GDIPOBJ,
	Types, GDIPAPI, Math, ToolTipManager, Menus, TB2Item, TB2Dock, TB2Toolbar, TB2MRU,
	BackgroundWorker,
	StdCtrls, TB2ExtItems;

const
	clEdgeColor = clRed;
	clDisabledEdgeColor = clGray;
	clEdgeHighlightedColor = clWebOrange;
	clEdgeRemoveColor = clBlue;

type
	TNodeAction = (naNothing, naNewNode, naShortestPath, naShortestPath_SelDest, naMinTree,
		naMaxFlow, naMaxFlow_SelDest, naActionComplete);

	ENodeNotFoundError = class(Exception)
	end;

	TMDIChild = class(TForm)
		ImageList1: TImageList;
		ToolTipManager1: TToolTipManager;
		SaveDialog1: TSaveDialog;
		NodePopupMenu: TPopupMenu;
		NodeDeleteMenuItem: TMenuItem;
		EdgePopupMenu: TPopupMenu;
		EmptySpacePopupMenu: TPopupMenu;
		EdgeDeleteMenuItem: TMenuItem;
		EdgeEditWeightMenuItem: TMenuItem;
		TBDock1: TTBDock;
		TBToolbar1: TTBToolbar;
		TBItem1: TTBItem;
		TBItem2: TTBItem;
		TBItem3: TTBItem;
		TBItem4: TTBItem;
		TBItem5: TTBItem;
		Panel1: TPanel;
		DragChangesPBox: TPaintBox;
		MainImage: TImage;
		NormalNodeImage: TImage;
		TempNodeImgSrc: TImage;
		TempNodeImg: TImage;
		ConnectNormalImg: TImage;
		ConnectLoserImg: TImage;
		MakeConnectionCursor: TImage;
		DestroyConnectionCursor: TImage;
		ConnectReceiverImg: TImage;
		SelectedNodeImage: TImage;
		LogWnd: TMemo;
		TBItem6: TTBItem;
		TBToolbar2: TTBToolbar;
		chkShowFlow: TCheckBox;
		TBControlItem1: TTBControlItem;
		TBControlItem2: TTBControlItem;
		chkShowDirection: TCheckBox;
    WeightUnderscorePrompt: TTimer;
    Debug_StepBtn: TButton;
		procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
		procedure MainPaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
			X, Y: Integer);
		procedure MainPaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
			_X, _Y: Integer);
		procedure MainPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; _X, _Y: Integer);
		procedure FormCreate(Sender: TObject);
		procedure NewNodeBtnClick(Sender: TObject);
		procedure DragChangesPBoxPaint(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure DragChangesPBoxDblClick(Sender: TObject);
		procedure Panel1Resize(Sender: TObject);
		procedure FormActivate(Sender: TObject);
		procedure NodeDeleteMenuItemClick(Sender: TObject);
		procedure EdgeDeleteMenuItemClick(Sender: TObject);
		procedure EdgeEditWeightMenuItemClick(Sender: TObject);
		procedure TBItem1Click(Sender: TObject);
		procedure TBItem2Click(Sender: TObject);
		procedure TBItem3Click(Sender: TObject);
		procedure TBItem4Click(Sender: TObject);
		procedure TBItem5Click(Sender: TObject);
		procedure Debug_StepBtnClick(Sender: TObject);
		procedure BackgroundWorker1Work(Worker: TBackgroundWorker);
		procedure TBItem6Click(Sender: TObject);
		procedure chkShowFlowClick(Sender: TObject);
		procedure chkShowDirectionClick(Sender: TObject);
		procedure FormKeyPress(Sender: TObject; var Key: Char);
    	procedure WeightUnderscorePromptTimer(Sender: TObject);
	private
		{ Private declarations }
		QueuedConnections: TList<Integer>; // connections indexes queued for deletion
		// The button is clicked and new node is to be placed somewhere on the form
		NodeAction: TNodeAction;
		LastHoveredPixel: Integer;
		LastPressedTBItem: TTBItem;
		CurHoveredEdge: TConnection;
		CurConStateImgs: array [0 .. 1] of TImage;
		CurX, CurY: Integer; // Current cursor X and Y pos when moving mouse with MouseDown
		Bounds: TRect;
		fFilePath: String;
		fChanges: Boolean;
		fPaused: Boolean;
		bShowFlow: Boolean;

        bTimer_HasUnderscore: Boolean;
		procedure ClearFlags;
		procedure SetChanges(Value: Boolean);
	public
		{ Public declarations }
		DataStore: TDataStore;
		NodeSelected: Boolean;
		SelNodeAdjacVertices: TObjectList<TNode>;
		SelectedNode: TNode;
		NodeDirection: TNodeDirection; // ([ssShift, ssCtrl] in MouseDown_Shift)
		ConnectNodes: Boolean; // (ssAlt in MouseDown_Shift)
		StringFormat: TGPStringFormat;
		_Font: TGPFont;
		property ChangesMade: Boolean read fChanges write SetChanges;
		function SaveDocument(): Boolean;
		function GetNode(X, Y: LongInt; ExcludeNode: TNode = nil): TNode;
		procedure RepaintMainImage;
		procedure SetStatus(Text: String);
		procedure AddLogMsg(Text: String);
		procedure AddFormattedLogMsg(FormatStr: String; Params: array of const );
		procedure ClearLog();
		procedure LoadFile(Filename: String);
{$IFDEF DEBUG}
		procedure Debug_GetPaused();
{$ENDIF}
	end;

procedure GetDXDY(PointStart, PointEnd: TPoint; Var dX, dY: Single);

Var
	MDIChild_DONT_USE_IT: TMDIChild;

implementation

uses Main, EdgeEditUnit, Algo, AllItemsUnit, DateUtils;
{$R *.dfm}

const
	TextOutDelta = 7;

	/// ////////////////////
	/// /// Main Form //////
	/// ////////////////////
function TMDIChild.SaveDocument(): Boolean;
Var
	FS: TFileStream;
begin
	Result := False;
	try
		if fFilePath = '' then
		begin
			if SaveDialog1.Execute then
				fFilePath := SaveDialog1.Filename
			else
				exit;
		end;
		FS := TFileStream.Create(fFilePath, fmCreate);
		DataStore.Serialize(FS);
		FS.Free;
		ChangesMade := False;
		Result := True;
		Caption := ExtractFileName(fFilePath);
	except
		Result := False;
	end;
end;

procedure TMDIChild.LoadFile(Filename: String);
Var
	FS: TFileStream;
begin
	if not FileExists(Filename) then
		exit;
	try
		FS := TFileStream.Create(Filename, fmOpenRead);
		DataStore.Deserialize(FS);
		FS.Free;
		fFilePath := Filename;
		Caption := ExtractFileName(fFilePath);
		RepaintMainImage;
        CoreForm.TBMRUList1.Add(Filename);
	except

	end;
end;

{$IFDEF DEBUG}
procedure TMDIChild.Debug_GetPaused();
begin
	fPaused := True;
	RepaintMainImage;

	while fPaused do
	begin
		Application.ProcessMessages;
		Sleep(100);
	end;
end;
{$ENDIF}

procedure TMDIChild.SetStatus(Text: String);
begin
	CoreForm.StatusBar.SimpleText := Text;
end;

procedure TMDIChild.AddLogMsg(Text: String);
begin
	LogWnd.Lines.Append('[' + TimeToStr(Now) + '] ' + Text);
end;

procedure TMDIChild.AddFormattedLogMsg(FormatStr: String; Params: array of const );
begin
	AddLogMsg(Format(FormatStr, Params));
end;

procedure TMDIChild.ClearLog();
begin
	LogWnd.Clear;
end;

procedure TMDIChild.TBItem1Click(Sender: TObject);
begin
	ClearFlags;
	LastPressedTBItem.Checked := False;
	LastPressedTBItem := TBItem1;
	LastPressedTBItem.Checked := True;
	NewNodeBtnClick(Sender);
end;

procedure TMDIChild.TBItem2Click(Sender: TObject);
begin
	ClearFlags;
	LastPressedTBItem.Checked := False;
	LastPressedTBItem := TBItem2;
	LastPressedTBItem.Checked := True;
	NodeAction := naShortestPath;
    SetStatus('Выберите начало пути - кликните на любую вершину');
end;

procedure TMDIChild.TBItem3Click(Sender: TObject);
begin
	ClearFlags;
	LastPressedTBItem.Checked := False;
	LastPressedTBItem := TBItem3;
	LastPressedTBItem.Checked := True;

	MinSpanningTree(DataStore);
	NodeAction := naActionComplete;
	RepaintMainImage;
end;

procedure TMDIChild.TBItem4Click(Sender: TObject);
begin
	ClearFlags;
	LastPressedTBItem.Checked := False;
	LastPressedTBItem := TBItem4;
	LastPressedTBItem.Checked := True;
	NodeAction := naMaxFlow;
    SetStatus('Выберите исток - кликните на любую вершину');
end;

procedure TMDIChild.TBItem5Click(Sender: TObject);
begin
	NodeAction := naNothing;
	LastPressedTBItem.Checked := False;
	ClearFlags;
end;

procedure TMDIChild.TBItem6Click(Sender: TObject);
begin
	AllItemsForm.Parent := Self;
	AllItemsForm.UpdateData(DataStore);
	AllItemsForm.Show;
end;

procedure TMDIChild.WeightUnderscorePromptTimer(Sender: TObject);
Var EdgeText: String;
begin
	if CurHoveredEdge = nil then
    	exit;
	with CurHoveredEdge do
    begin
        EdgeText := IntToStr(Weight);
        if bShowFlow then
            EdgeText := EdgeText + '/' + IntToStr(Flow);

        if bTimer_HasUnderscore then
        	EdgeText := EdgeText + '_';

        DragChangesPBox.Repaint;
        with DragChangesPBox.Canvas do
        begin
        	Refresh;
            SetBkMode(Handle, Windows.TRANSPARENT);
            TextOut(Trunc((Key.Point.X + Value.Point.X) / 2),
                Trunc((Key.Point.Y + Value.Point.Y) / 2), EdgeText);
        end;
    end;
    bTimer_HasUnderscore := not bTimer_HasUnderscore;
end;

procedure TMDIChild.BackgroundWorker1Work(Worker: TBackgroundWorker);
begin
	MinSpanningTree(DataStore);
end;

procedure TMDIChild.Debug_StepBtnClick(Sender: TObject);
begin
	fPaused := False;
end;

procedure TMDIChild.chkShowDirectionClick(Sender: TObject);
begin
	DataStore.IgnoreDirection := not chkShowDirection.Checked;
	ClearFlags;
end;

procedure TMDIChild.chkShowFlowClick(Sender: TObject);
begin
	bShowFlow := chkShowFlow.Checked;
	RepaintMainImage;
end;

procedure TMDIChild.ClearFlags;
var
	I: Integer;
begin
	with DataStore do
	begin
		with Nodes do
			for I := 0 to Count - 1 do
			begin
				Items[I].Flag := mfNormal;
			end;

		with Connections do
			for I := 0 to Count - 1 do
			begin
				with Items[I] do
					if Flag <> mfNormal then
					begin
						Items[I].Flag := mfNormal;
						Flow := 0;
					end;
			end;
	end;
	RepaintMainImage;
end;

procedure TMDIChild.SetChanges(Value: Boolean);
begin
	fChanges := Value;
	FormActivate(Self);
end;

procedure TMDIChild.FormActivate(Sender: TObject);
begin
	(Application.MainForm as TCoreForm).MDIChildChanged;
end;

procedure TMDIChild.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Action := caFree;
	// if Action <> caFree then
	// exit;
end;

procedure TMDIChild.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	if not ChangesMade then
		exit;

	case MessageDlg('Есть несохранённые данные. Сохранить?', mtInformation, mbYesNoCancel, 0) of
	IDYES:
		CanClose := SaveDocument;
	IDCANCEL:
		CanClose := False;
	end;

end;

procedure TMDIChild.FormCreate(Sender: TObject);
begin
	MainImage.Canvas.FloodFill(0, 0, clWhite, fsSurface);

	StringFormat := TGPStringFormat.Create(TGPStringFormat.GenericDefault);
	StringFormat.SetTrimming(StringTrimmingEllipsisCharacter);
	StringFormat.SetAlignment(StringAlignmentCenter);
	StringFormat.SetLineAlignment(StringAlignmentCenter);
	_Font := TGPFont.Create(Canvas.Handle);
	QueuedConnections := TList<Integer>.Create;
	SelNodeAdjacVertices := TObjectList<TNode>.Create(False);
	DataStore := TDataStore.Create;

	LastPressedTBItem := TBItem5;
	LogWnd.Clear;
end;

procedure TMDIChild.FormDestroy(Sender: TObject);
begin
	_Font.Free;
	StringFormat.Free;
	QueuedConnections.Free;
	SelNodeAdjacVertices.Free;
	DataStore.Free; // Self-freed now
end;

procedure TMDIChild.FormKeyPress(Sender: TObject; var Key: Char);
Var
	_Str: String;
begin
	if (CurHoveredEdge <> nil) and (CharInSet(Key, ['0' .. '9', #8])) then
	begin
		_Str := IntToStr(CurHoveredEdge.Weight);
		if Key = #8 then
		begin
			if Length(_Str) = 1 then
				_Str := '0'
			else
				SetLength(_Str, Length(_Str) - 1);
		end
		else
		begin
			if _Str = '0' then
				_Str := '';
			_Str := _Str + Key;
		end;
		CurHoveredEdge.Weight := StrToInt(_Str);
		RepaintMainImage;
	end
	else if (CurHoveredEdge <> nil) and (CharInSet(Key, ['0' .. '9', #8])) then

end;

function TMDIChild.GetNode(X, Y: LongInt; ExcludeNode: TNode = nil): TNode;
const
	CursorRadius = 1;
var
	NodeRadius: Integer;
	I: Integer;
	NodeRC: TRect;
	CurNode: TNode;
	CursorPoint: TPoint;
begin
	NodeRadius := Trunc(NormalNodeImage.Width / 2);
	CursorPoint := Classes.Point(X, Y);

	for I := 0 to DataStore.Nodes.Count - 1 do
	begin
		CurNode := DataStore.Nodes[I];
		with CurNode.Point do
			NodeRC := Rect(X - NodeRadius, Y - NodeRadius, X + NodeRadius, Y + NodeRadius);

		if PtInRect(NodeRC, CursorPoint) then
		begin
			if CurNode = ExcludeNode then
				continue;

			Result := CurNode;
			exit;
		end;
	end;
	Result := nil;
end;

procedure TMDIChild.MainPaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
	X, Y: Integer);
Var
	Node: TNode;
	Pos: TPoint;
	Xc, Yc: Integer;
	Graphics: TGPGraphics;
	TextBrush: TGPBrush;
	I: Integer;

	procedure InitTempNodeImg();
	Var
		NodeImgDestCanvas: TCanvas;
	begin
		NodeImgDestCanvas := (TempNodeImg.Picture.Graphic as TPngImage).Canvas;
		with (TempNodeImgSrc.Picture.Graphic as TPngImage) do
		begin
			DrawUsingPixelInformation(NodeImgDestCanvas, Classes.Point(0, 0));
			Graphics := TGPGraphics.Create(NodeImgDestCanvas.Handle);
			TextBrush := TGPSolidBrush.Create($FF000000);
			Graphics.SetTextRenderingHint(TextRenderingHintAntiAlias);
			Graphics.DrawString(IntToStr(SelectedNode.ID), -1, _Font,
				MakeRect(0.0, 0.0, Width, Height), StringFormat, TextBrush);
			TextBrush.Free;
			Graphics.Free;
		end;
		with TempNodeImg do
		begin
			Visible := True;
			Left := X - Xc;
			Top := Y - Yc;
		end;
	end;

begin
	Xc := Trunc(TempNodeImg.Width / 2);
	Yc := Trunc(TempNodeImg.Height / 2);

	case NodeAction of
	naNewNode:
		begin
			with DataStore do
			begin
				SelectedNode := AddNode(TNode.Create(Nodes, Pos));
			end;
			NodeSelected := True;
			InitTempNodeImg();
			NodeAction := naActionComplete;
		end;
	naShortestPath, naShortestPath_SelDest:
		begin
			Node := GetNode(X, Y);
			if Node = nil then
				exit;
			Node.Flag := mfMarked;
			RepaintMainImage;

			if NodeAction = naShortestPath_SelDest then
			begin
				GetShortestPath(DataStore, SelectedNode, Node);
				NodeAction := naActionComplete;
			end
			else
			begin
				NodeAction := naShortestPath_SelDest;
				SelectedNode := Node;
                SetStatus('Выберите конец пути - кликните на любую другую вершину');
			end;
		end;
	naMaxFlow, naMaxFlow_SelDest:
		begin
			Node := GetNode(X, Y);
			if Node = nil then
				exit;
			Node.Flag := mfMarked;
			RepaintMainImage;

			if NodeAction = naMaxFlow_SelDest then
			begin
				AddFormattedLogMsg('Максимальный поток: %d',
					[Maxflow(DataStore, SelectedNode, Node)]);
				NodeAction := naActionComplete;
			end
			else
			begin
				NodeAction := naMaxFlow_SelDest;
				SelectedNode := Node;
                SetStatus('Выберите сток - кликните на любую другую вершину');
			end;
		end;
	naMinTree:
		begin
			// Node := GetNode(X, Y);
			// if Node = nil then
			// exit;
			// Node.Flag := mfMarked;

			// MinSpanningTree(DataStore);
			// NodeAction := naActionComplete;

			// RepaintMainImage;
		end;
	else
		begin

			Node := GetNode(X, Y);
			if Node = nil then
				exit;
			SelectedNode := Node;
			NodeSelected := True;

			with DataStore.Connections do
				for I := 0 to Count - 1 do
				begin
					with Items[I] do
					begin
						if (Key = SelectedNode) then
							SelNodeAdjacVertices.Add(Value);

						if (Value = SelectedNode) then
							SelNodeAdjacVertices.Add(Key);
					end;
				end;

			// MouseDown_Shift := Shift;
			NodeDirection := 0;
			if (ssShift in Shift) then
				NodeDirection := NodeDirection or ndK2V;
			if (ssCtrl in Shift) then
				NodeDirection := NodeDirection or ndV2K;

			if NodeDirection <> 0 then
			begin
				ConnectNodes := (Button = mbLeft) or (Button = mbMiddle);
				if ConnectNodes then
				begin
					CurConStateImgs[0] := MakeConnectionCursor;
					CurConStateImgs[1] := ConnectReceiverImg;
				end
				else
				begin
					CurConStateImgs[0] := DestroyConnectionCursor;
					CurConStateImgs[1] := ConnectLoserImg;
				end;

				if (NodeDirection and ndK2V) <> 0 then
					with CurConStateImgs[0] do
					begin
						Left := X - 4;
						Top := Y - 4;
						Visible := True;
					end;
				if (NodeDirection and ndV2K) <> 0 then
					CurConStateImgs[1].Visible := True;

			end
			else if (Button = mbRight) then
			begin
				NodeSelected := False;
				exit;
			end
			else
				InitTempNodeImg();
		end;
	end;
end;

procedure GetDXDY(PointStart, PointEnd: TPoint; Var dX, dY: Single);
const
	PixelSize = 1;
Var
	X1, X2, Y1, Y2, L: Integer;
begin
	X1 := PointStart.X;
	Y1 := PointStart.Y;
	X2 := PointEnd.X;
	Y2 := PointEnd.Y;
	L := Max(abs(X2 - X1), abs(Y2 - Y1));
	if L = 0 then
		L := 1;
	dX := PixelSize * (X2 - X1) / L;
	dY := PixelSize * (Y2 - Y1) / L;
end;

procedure TMDIChild.MainPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; _X, _Y: Integer);
Var
	AdjacNode: TNode;
	dX, dY, Angle, R: Single;
    CurPixel: Integer;
begin

	if not NodeSelected then
	begin
		CurX := _X;
		CurY := _Y;

        CurPixel := MainImage.Canvas.Pixels[_X, _Y];
		// Is This a line we are at?
		if LastHoveredPixel <> CurPixel then
		begin
			if (CurPixel = clEdgeColor) or (CurPixel = clDisabledEdgeColor) then
			begin
				CurHoveredEdge := DataStore.GetSelEdgeFromPoint(Classes.Point(_X, _Y));
			end
			else
			begin
				CurHoveredEdge := nil;
			end;
			LastHoveredPixel := CurPixel;
			RepaintMainImage;
		end;

		if CurHoveredEdge <> nil then
		begin
			with ToolTipManager1.ToolTips[0] do
			begin
				Description := 'Вес ребра: ' + IntToStr(CurHoveredEdge.Weight);
				ToolTipManager1.Enabled := True;
			end;
		end
		else
			ToolTipManager1.Enabled := False;
	end
	else
	begin
		CurX := _X;
		CurY := _Y;

		if NodeDirection <> 0 then
		begin
			AdjacNode := GetNode(_X, _Y, SelectedNode);
			if AdjacNode <> nil then
			begin
				if ConnectNodes then
				begin
					// SelectedNode.AddVertex(AdjacNode);
					DataStore.QueryAddConnection(SelectedNode, AdjacNode, NodeDirection, 1);
					RepaintMainImage;
					SetStatus('Добавлена связь ' + IntToStr(SelectedNode.ID) + ' - ' +
						IntToStr(AdjacNode.ID));
				end
				else
				begin
					// SelectedNode.DeleteVertex(AdjacNode);
					DataStore.QueryDelConnection(SelectedNode, AdjacNode, NodeDirection);
					RepaintMainImage;
					SetStatus('Удалена связь ' + IntToStr(SelectedNode.ID) + ' - ' +
						IntToStr(AdjacNode.ID));
				end;
			end;

			if PtInRect(Bounds, Classes.Point(_X, _Y)) then
			begin
				if (NodeDirection and ndK2V) <> 0 then
				begin
					// Cursor
					with CurConStateImgs[0] do
					begin
						Left := _X - 8;
						Top := _Y - 8;
					end;
				end;

				if (NodeDirection and ndV2K) <> 0 then
				begin
					with SelectedNode do
					begin
						R := Trunc(NormalNodeImage.Width / 2);
						GetDXDY(Point.Point, Classes.Point(_X, _Y), dX, dY);
						Angle := ArcTan2(dX, dY);
						with CurConStateImgs[1] do
						begin
							Left := Point.X + Trunc(R * Sin(Angle)) - 4;
							Top := Point.Y + Trunc(R * Cos(Angle)) - 4;
						end;
					end;
				end;
			end;
		end
		else
		begin
			if PtInRect(Bounds, Classes.Point(_X, _Y)) then
			begin
				with TempNodeImg do
				begin
					Left := _X - Trunc(Width / 2);
					Top := _Y - Trunc(Height / 2);
				end;

				with SelectedNode.Point do
				begin
					X := _X;
					Y := _Y;
				end;
			end;
		end;
	end;

	DragChangesPBox.Refresh;
end;

procedure TMDIChild.MainPaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
	_X, _Y: Integer);
Var
	CursorPos: TPoint;
begin

	if NodeSelected then
	begin
		NodeSelected := False;
		TempNodeImg.Visible := False;

		DataStore.ApplyQueries;

		if NodeDirection <> 0 then
		begin
			CurConStateImgs[0].Visible := False;
			CurConStateImgs[1].Visible := False;
		end
		else
		begin
			if PtInRect(Bounds, Classes.Point(_X, _Y)) then
				with SelectedNode.Point do
				begin
					X := _X;
					Y := _Y;
				end;
			DataStore.NotifyLocationChanges(SelectedNode);
		end;

		RepaintMainImage;
		ChangesMade := True;
	end
	else if (Button = mbRight) and (NodeAction = naNothing) then
	begin
		CursorPos := MainImage.ClientToScreen(Point(_X, _Y));
		if CurHoveredEdge <> nil then
		begin
			EdgePopupMenu.Popup(CursorPos.X, CursorPos.Y);
		end
		else
		begin
			if GetNode(_X, _Y) <> nil then
			begin
				NodePopupMenu.Popup(CursorPos.X, CursorPos.Y);
			end;
		end;
	end;
	SelNodeAdjacVertices.Clear;
		
	if NodeAction = naActionComplete then
	begin
		NodeAction := naNothing;
		LastPressedTBItem.Checked := False;
	end;

    if (NodeAction = naNothing) then
		SetStatus('Готово');

	NodeDirection := 0;
end;

procedure TMDIChild.NewNodeBtnClick(Sender: TObject);
begin
	NodeAction := naNewNode;
end;

procedure TMDIChild.NodeDeleteMenuItemClick(Sender: TObject);
begin
	DataStore.DeleteNode(SelectedNode);
	RepaintMainImage;
end;

procedure TMDIChild.Panel1Resize(Sender: TObject);
begin
	with Panel1 do
	begin
		MainImage.Width := Width;
		MainImage.Height := Height;

		DragChangesPBox.Width := Width;
		DragChangesPBox.Height := Height;

		if Assigned(MainImage.Picture.Graphic) then
		begin
			MainImage.Picture.Graphic.Width := Width;
			MainImage.Picture.Graphic.Height := Height;
		end;
		RepaintMainImage;
		Bounds := ClientRect;
	end;
end;

procedure TMDIChild.RepaintMainImage;
var
	I, W, H: Integer;
	NodeImg: TImage;
	EdgeText: String;
{$IFDEF UseGDIPlus}
	Graphics: TGPGraphics;
	GPPen: TGPPen;
{$ENDIF}
	procedure _AddArrows(_ImageK2V: TImage; Connection: TConnection; _ImageV2K: TImage = nil);
	const
		delta = 2;
	var
		X, Y, Angle: Single;
		ImageK2V, ImageV2K: TPngImage;
	begin
		if DataStore.IgnoreDirection then
			exit;

		if _ImageK2V <> nil then
			ImageK2V := (_ImageK2V.Picture.Graphic as TPngImage)
		else if _ImageV2K <> nil then
			ImageK2V := (_ImageV2K.Picture.Graphic as TPngImage)
		else
			exit;

		if _ImageV2K <> nil then
			ImageV2K := (_ImageV2K.Picture.Graphic as TPngImage)
		else
			ImageV2K := ImageK2V;

		with Connection do
		begin
			if (Direction and ndK2V) <> 0 then
			begin
				Angle := ArcTan2(dX, dY);
				X := Value.Point.X + Trunc(-(W + delta) * Sin(Angle));
				Y := Value.Point.Y + Trunc(-(W + delta) * Cos(Angle));
				with ImageK2V do
					DrawUsingPixelInformation(MainImage.Canvas,
						Classes.Point(Trunc(X) - 4, Trunc(Y) - 4));
			end;

			if (Direction and ndV2K) <> 0 then
			begin
				Angle := ArcTan2(dY, dX);
				X := Key.Point.X + Trunc((W + delta) * Cos(Angle));
				Y := Key.Point.Y + Trunc((W + delta) * Sin(Angle));
				with ImageV2K do
					DrawUsingPixelInformation(MainImage.Canvas,
						Classes.Point(Trunc(X) - 4, Trunc(Y) - 4));
			end;
		end;
	end;

	procedure AddArrows(Operation: TPendingOp); overload;
	Var
		K2VImg, V2KImg: TImage;
	begin
		if Operation.Operation = coAdd then
		begin
			if (Operation.PO_Direction and ndK2V) <> 0 then
				K2VImg := ConnectReceiverImg
			else
				K2VImg := ConnectNormalImg;

			if (Operation.PO_Direction and ndV2K) <> 0 then
				V2KImg := ConnectReceiverImg
			else
				V2KImg := ConnectNormalImg;
		end
		else
		begin
			if (Operation.PO_Direction and ndK2V) <> 0 then
				K2VImg := ConnectLoserImg
			else
				K2VImg := ConnectNormalImg;

			if (Operation.PO_Direction and ndV2K) <> 0 then
				V2KImg := ConnectLoserImg
			else
				V2KImg := ConnectNormalImg;

		end;
		_AddArrows(K2VImg, Operation.Connection, V2KImg);
	end;

begin
	if DataStore = nil then
		exit;

	W := Trunc(NormalNodeImage.Width / 2); // it's radius as well
	H := Trunc(NormalNodeImage.Height / 2);
	with DataStore, MainImage.Canvas do
	begin
{$IFDEF UseGDIPlus}
		Graphics := TGPGraphics.Create(Handle);
		Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
		GPPen := TGPPen.Create(ColorRefToARGB(clEdgeColor), 2);
{$ENDIF}
		FillRect(Rect(0, 0, MainImage.Width, MainImage.Height));
		for I := 0 to PendingOperations.Count - 1 do
		begin
			with PendingOperations[I] do
			begin
				case Operation of
				coAdd:
					begin
{$IFDEF UseGDIPlus}
						GPPen.SetDashStyle(DashStyleDash);
						GPPen.SetColor(ColorRefToARGB(clEdgeColor));
{$ELSE}
						Pen.Color := clEdgeColor;
						Pen.Style := psDash;
{$ENDIF}
					end;
				coDelete:
					begin
{$IFDEF UseGDIPlus}
						GPPen.SetDashStyle(DashStyleDash);
						GPPen.SetColor(ColorRefToARGB(clEdgeRemoveColor));
{$ELSE}
						Pen.Color := clEdgeRemoveColor;
						Pen.Style := psDash;
{$ENDIF}
					end;
				end;

				with Connection do
				begin
{$IFDEF UseGDIPlus}
					with Key.Point do
						Graphics.DrawLine(GPPen, X, Y, Value.Point.X, Value.Point.Y);
{$ELSE}
					MoveTo(Key.Point.X, Key.Point.Y);
					LineTo(Value.Point.X, Value.Point.Y);
{$ENDIF}
					GetDXDY(Key.Point.Point, Value.Point.Point, dX, dY);
				end;
				AddArrows(PendingOperations[I]);
			end;
		end;

		for I := 0 to Connections.Count - 1 do
		begin
			with Connections[I] do
			begin
				if ToBeChanged then
					continue;

{$IFDEF UseGDIPlus}
				if CurHoveredEdge = Connections[I] then
					GPPen.SetWidth(HoveredEdgeWidth)
				else
					GPPen.SetWidth(NormalEdgeWidth);

				GPPen.SetDashStyle(DashStyleSolid);
				case Flag of
				mfNormal:
                	if Weight = 0 then
                    	GPPen.SetColor(ColorRefToARGB(clDisabledEdgeColor))
                    else
						GPPen.SetColor(ColorRefToARGB(clEdgeColor));
				mfMarked:
					GPPen.SetColor(ColorRefToARGB(clEdgeHighlightedColor));
				mfMarkedBold:
					begin
						GPPen.SetColor(ColorRefToARGB(clEdgeHighlightedColor));
						GPPen.SetWidth(HoveredEdgeWidth);
					end;
				end;

				Graphics.DrawLine(GPPen, Key.Point.X, Key.Point.Y, Value.Point.X, Value.Point.Y);
{$ELSE}
				if CurHoveredEdge = Connections[I] then
					Pen.Width := HoveredEdgeWidth
				else
					Pen.Width := NormalEdgeWidth;

				Pen.Style := psSolid;
				case Flag of
				mfNormal:
                	if Weight = 0 then
                    	Pen.Color := clDisabledEdgeColor
                    else
						Pen.Color := clEdgeColor;
				mfMarked:
					Pen.Color := clEdgeHighlightedColor;
				mfMarkedBold:
					begin
						Pen.Color := clEdgeHighlightedColor;
						Pen.Width := HoveredEdgeWidths;
					end;
				end;

				MoveTo(Key.Point.X, Key.Point.Y);
				LineTo(Value.Point.X, Value.Point.Y);
{$ENDIF}
				// SetBkMode(Handle, Windows.OPAQUE);
				// SetBkColor(Handle, clWhite);
				EdgeText := IntToStr(Weight);
				if bShowFlow then
					EdgeText := EdgeText + '/' + IntToStr(Flow);
				SetBkMode(Handle, Windows.TRANSPARENT);
				TextOut(Trunc((Key.Point.X + Value.Point.X) / 2),
					Trunc((Key.Point.Y + Value.Point.Y) / 2), EdgeText);
				// SetBkMode(Handle, Windows.TRANSPARENT);

				GetDXDY(Key.Point.Point, Value.Point.Point, dX, dY);
				_AddArrows(ConnectNormalImg, Connections[I]);
			end;
		end;

		for I := 0 to Nodes.Count - 1 do
		begin
			with Nodes[I] do
			begin
				case Flag of
				mfNormal:
					NodeImg := NormalNodeImage;
				mfMarked:
					NodeImg := SelectedNodeImage;
				end;

				with Point, (NodeImg.Picture.Graphic as TPngImage) do
				begin
					SetBkMode(Handle, Windows.TRANSPARENT);
					DrawUsingPixelInformation(MainImage.Canvas, Classes.Point(X - W, Y - H));
					TextOut(X - TextOutDelta, Y - TextOutDelta, IntToStr(ID));
				end;
			end;
		end;
{$IFDEF UseGDIPlus}
		GPPen.Free;
		Graphics.Free;
{$ENDIF}
	end;
end;

procedure TMDIChild.DragChangesPBoxDblClick(Sender: TObject);
begin
	if CurHoveredEdge <> nil then
	begin
		EdgeEditWeightMenuItemClick(Sender);
	end
	else
	begin
		NewNodeBtnClick(Sender);
	end;
end;

procedure TMDIChild.DragChangesPBoxPaint(Sender: TObject);
var
	I: Integer;
{$IFDEF UseGDIPlus}
	Graphics: TGPGraphics;
	GPPen: TGPPen;
{$ENDIF}
begin
	if (not NodeSelected) then
		exit;

	if NodeDirection <> 0 then
	begin
		with DragChangesPBox.Canvas, SelectedNode do
		begin
{$IFDEF UseGDIPlus}
			Graphics := TGPGraphics.Create(Handle);
			Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
			GPPen := TGPPen.Create(ColorRefToARGB(clEdgeColor), 2);
			if ConnectNodes then
				GPPen.SetColor(ColorRefToARGB(clEdgeColor))
			else
				GPPen.SetColor(ColorRefToARGB(clEdgeRemoveColor));

			GPPen.SetDashStyle(DashStyleDash);
			Graphics.DrawLine(GPPen, Point.X, Point.Y, CurX, CurY);
			GPPen.Free;
			Graphics.Free;
{$ELSE}
			if ConnectNodes then
				Pen.Color := clEdgeColor
			else
				Pen.Color := clEdgeRemoveColor;
			Pen.Style := psDash;
			MoveTo(Point.X, Point.Y);
			LineTo(CurX, CurY);
{$ENDIF}
		end;
	end
	else
		with DragChangesPBox.Canvas, SelectedNode do
		begin
{$IFDEF UseGDIPlus}
			Graphics := TGPGraphics.Create(Handle);
			Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
			GPPen := TGPPen.Create(ColorRefToARGB(clEdgeColor), 2);

			GPPen.SetColor(ColorRefToARGB(clEdgeColor));
			GPPen.SetDashStyle(DashStyleDash);

			for I := 0 to SelNodeAdjacVertices.Count - 1 do
			begin
				with Point.Point do
					Graphics.DrawLine(GPPen, X, Y, SelNodeAdjacVertices[I].Point.X,
						SelNodeAdjacVertices[I].Point.Y);
			end;

			GPPen.Free;
			Graphics.Free;
{$ELSE}
			Pen.Color := clEdgeColor;
			Pen.Style := psDash;

			for I := 0 to SelNodeAdjacVertices.Count - 1 do
			begin
				with SelNodeAdjacVertices[I] do
					MoveTo(Point.X, Point.Y);
				LineTo(Point.X, Point.Y);
			end;
{$ENDIF}
		end;
end;

procedure TMDIChild.EdgeDeleteMenuItemClick(Sender: TObject);
begin
	DataStore.DelConnection(CurHoveredEdge);
	RepaintMainImage;
end;

procedure TMDIChild.EdgeEditWeightMenuItemClick(Sender: TObject);
Var
	EdgeEditForm: TEdgeEditForm;
begin
	if CurHoveredEdge <> nil then
	begin
		EdgeEditForm := TEdgeEditForm.Create(nil);
		EdgeEditForm.Weight := CurHoveredEdge.Weight;
		if EdgeEditForm.ShowModal = mrOK then
			CurHoveredEdge.Weight := EdgeEditForm.Weight;
		EdgeEditForm.Free;
	end;
end;

end.
