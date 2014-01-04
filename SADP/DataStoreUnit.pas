unit DataStoreUnit;

interface

uses Windows, Classes, SysUtils, Generics.Collections, Generics.Defaults, Math;

const
	ndK2V = 1;
	ndV2K = 2;

	HoveredEdgeWidth_StartFrom = -3;
	HoveredEdgeWidth_EndAt = 3;
	HoveredEdgeWidth = HoveredEdgeWidth_EndAt - HoveredEdgeWidth_StartFrom;
	NormalEdgeWidth = 2;

type

	TNPoint = record
		case Integer of
		0:
			(X: Longint;
				Y: Longint);
		1:
			(Point: TPoint);
	end;

	TNodeID = Integer;

    TMarkupFlag = (mfNormal, mfMarked, mfMarkedBold);

	TNode = class
	private
		// fPoint: TNPoint;
        fFlag: TMarkupFlag;
		fID: TNodeID;
        fOwner: TObjectList<TNode>;
		// fAdjacVertices: TObjectList<TNode>;
		function GetID: TNodeID;
	public
		Point: TNPoint; // property Point: TNPoint read fPoint write fPoint;
        property Flag: TMarkupFlag read fFlag write fFlag;
		property ID: TNodeID read GetID;
		// property AdjacVertices: TObjectList<TNode> read fAdjacVertices;
		procedure OnNodesListChange;
		// procedure OnDeserializationComplete;
		procedure Serialize(Stream: TStream);
		procedure Deserialize(Stream: TStream);
		// procedure DeleteVertex(Vertex: TNode; DeleteInResponse: Boolean = True);
		// procedure AddVertex(Vertex: TNode; AddInResponse: Boolean = True);
		constructor Create(Owner: TObjectList<TNode>); overload;
		constructor Create(Owner: TObjectList<TNode>; _Point: TPoint); overload;
		destructor Destroy; override;
	end;

	// TNodeDirection = set of (ndK2V, ndV2K);
	TNodeDirection = Integer;

	TIsPointOnEdgeProc = reference to function(Point: TPoint): Boolean;
    TConnectionList = class;
	TConnection = class
	private
		A, B, C: Extended; // Line Coeffs
		fIsPointOnTheEdge: TIsPointOnEdgeProc;
        fDirection: TNodeDirection;
        Owner: TConnectionList;
		procedure GetLineCoefsFromTwoPoints(Var A, B, C: Extended);
        function _GetDirection: TNodeDirection;
		procedure _SetDirection(Value: TNodeDirection);
	public
		dX, dY: Single;
		Key: TNode;
		Value: TNode;
		Weight: Integer;
        Flow: Integer;
        Flag: TMarkupFlag;
		ToBeChanged: Boolean; // There's an operation to be done in PendingOperations list
		property IsPointOnTheEdge: TIsPointOnEdgeProc read fIsPointOnTheEdge;
		property Direction: TNodeDirection read _GetDirection write _SetDirection;
		procedure SetDirection(_Key, _Value: TNode; _Direction: TNodeDirection);
		procedure NotifyNodeLocationChange();
		procedure AddDirection(_From, _To: TNode; Queue: Boolean = True);
		procedure DelDirection(_From, _To: TNode; SelfRemove: Boolean = True);
		constructor Create(const AKey: TNode; const AValue: TNode; const _Weight: Integer;
			const ConnectionFlags: TNodeDirection; const OwnerList: TConnectionList);
        destructor Destroy; override;
	end;

    TSettingsProvider = class
    protected
    	fIgnoreDirection: Boolean;
    public
    	function GetIgnoreDirection: Boolean;
    end;

	TConnectionList = class(TObjectList<TConnection>)
    private
    	fSettings: TSettingsProvider;
    public
        function GetIgnoreDirection: Boolean;
        // Ignore connections direction (all connections are set to (ndV2K or ndK2V))
        constructor Create(Owner: TSettingsProvider); overload;
        constructor Create(Owner: TSettingsProvider; const AComparer: IComparer<TConnection>; AOwnsObjects: Boolean = True); overload;
    end;

	TConnOperation = (coAdd, coDelete);

    TPendingOpList = class;
	TPendingOp = class
    private
    	fSettings: TSettingsProvider;
    public
		Owner: TObjectList<TPendingOp>;
		OwnsConnectionObj: Boolean;
		Connection: TConnection;
		PO_Direction: TNodeDirection;
		Operation: TConnOperation;

		function GetIgnoreDirection: Boolean;

    	procedure AddDirection(_From, _To: TNode; Queue: Boolean = True);
		procedure DelDirection(_From, _To: TNode; Queue: Boolean = True);
        function Remove(const Value: TConnection): Integer;

        constructor Create(Owner: TSettingsProvider);
        destructor Destroy; override;
	end;

    TPendingOpList = class(TObjectList<TPendingOp>)
    private
        fSettings: TSettingsProvider;
    public
        function GetIgnoreDirection: Boolean;
        constructor Create(Owner: TSettingsProvider);
    end;

	TGetConProc = reference to function(Idx: Integer): TConnection;

	TDataStore = class(TSettingsProvider)
	private
		fLastHoveredEdge: TConnection;
		fDestroying: Boolean;
        fLastAddedNode: TNode;

		procedure NotifyConnectionChanges(Sender: TObject; const Item: TConnection;
			Action: TCollectionNotification);
    	procedure NotifyNodeChanges(Sender: TObject; const Item: TNode;
			Action: TCollectionNotification);
		procedure QueueAction(Action: TConnOperation; VertexKey, VertexValue: TNode;
			_Direction: TNodeDirection; Weight: Integer);
		function FindItemInList(Count: Integer; GetItemProc: TGetConProc;
			VertexKey, VertexValue: TNode; _Direction: TNodeDirection = ndK2V + ndV2K;
			ORdirection: Boolean = True): Integer;

		procedure SetIgnoreDirection(Value: Boolean);
    public
		PendingOperations: TPendingOpList;
		Connections: TConnectionList;
		Nodes: TObjectList<TNode>;
		property Destroying: Boolean read fDestroying; // for the nodes to correctly free themselves
        property LastAddedNode: TNode read fLastAddedNode;
       	property IgnoreDirection: Boolean read GetIgnoreDirection write SetIgnoreDirection;
		// ORdirection works if Direction = ndBoth and searches for
		// ndBoth connection only if it is False
        function LoseConnections(Node: TNode): Integer;
        function DeleteNode(Node: TNode): Integer;
        function AddNode(Node: TNode): TNode;

		function FindConnection(VertexKey, VertexValue: TNode;
			_Direction: TNodeDirection = ndK2V + ndV2K; ORdirection: Boolean = True): Integer;
		function FindQuery(VertexKey, VertexValue: TNode;
			_Direction: TNodeDirection = ndK2V + ndV2K; ORdirection: Boolean = True): Integer;
		procedure AddConnection(VertexKey, VertexValue: TNode; Direction: TNodeDirection;
			Weight: Integer);
		procedure DelConnection(VertexKey, VertexValue: TNode; _Direction: TNodeDirection);
			overload;
		procedure DelConnection(Connection: TConnection); overload;
		procedure QueryAddConnection(VertexKey, VertexValue: TNode; Direction: TNodeDirection;
			Weight: Integer);
		procedure QueryDelConnection(VertexKey, VertexValue: TNode; Direction: TNodeDirection);
		procedure ApplyQueries;
		function GetSelEdgeFromPoint(Point: TPoint): TConnection;
		procedure NotifyLocationChanges(Node: TNode);
		// procedure DelConnection(Index: Integer); overload;
		function GetNodeByID(VertexID: TNodeID): TNode;
		procedure Serialize(Stream: TStream);
		procedure Deserialize(Stream: TStream);
		procedure Clear;
		constructor Create;
		destructor Destroy; override;
	end;

implementation

uses MainFrm;

const
	Eps = 0.1;
	Eps2 = 10E-8;

function TSettingsProvider.GetIgnoreDirection: Boolean;
begin
	Result := fIgnoreDirection;
end;

// ////////////// //
// TPendingOpList //
// ////////////// //
function TPendingOpList.GetIgnoreDirection: Boolean;
begin
	Result := fSettings.GetIgnoreDirection;
end;
constructor TPendingOpList.Create(Owner: TSettingsProvider);
begin
    fSettings := Owner;
    inherited Create;
end;

// //////////////// //
// TConnectionsList //
// //////////////// //
function TConnectionList.GetIgnoreDirection: Boolean;
begin
	Result := fSettings.GetIgnoreDirection;
end;
constructor TConnectionList.Create(Owner: TSettingsProvider);
begin
	fSettings := Owner;
    inherited Create;
end;
constructor TConnectionList.Create(Owner: TSettingsProvider; const AComparer: IComparer<TConnection>; AOwnsObjects: Boolean = True);
begin
	fSettings := Owner;
    inherited Create(AComparer, AOwnsObjects);
end;


// ////////// //
// TPendingOp //
// ////////// //
procedure TPendingOp.AddDirection(_From, _To: TNode; Queue: Boolean = True);
begin
	with Connection do
	begin
		if (_From = Key) and (_To = Value) then
			PO_Direction := PO_Direction or ndK2V
		else
			PO_Direction := PO_Direction or ndV2K;
	end;
end;
procedure TPendingOp.DelDirection(_From, _To: TNode; Queue: Boolean = True);
begin
	with Connection do
	begin
		if (_From = Key) and (_To = Value) then
			PO_Direction := PO_Direction and (not ndK2V)
		else
			PO_Direction := PO_Direction and (not ndV2K);
	end;
	if Connection.Direction = 0 then
		Owner.Remove(Self);
end;

function TPendingOp.GetIgnoreDirection: Boolean;
begin
	Result := fSettings.GetIgnoreDirection;
end;

constructor TPendingOp.Create(Owner: TSettingsProvider);
begin
	fSettings := Owner;
    inherited Create;
end;

destructor TPendingOp.Destroy;
begin
	if Self <> nil then
		inherited;
end;

function TPendingOp.Remove(const Value: TConnection): Integer;
begin
	//if Value = Connection then
	//	Destroy;
    Result := 0;
end;
// /////////// //
// TConnection //
// /////////// //
procedure TConnection.GetLineCoefsFromTwoPoints(Var A, B, C: Extended);
begin
	A := Key.Point.Y - Value.Point.Y;
	B := Value.Point.X - Key.Point.X;
	C := Key.Point.X * Value.Point.Y - Key.Point.Y * Value.Point.X;
end;

constructor TConnection.Create(const AKey: TNode; const AValue: TNode; const _Weight: Integer;
	const ConnectionFlags: TNodeDirection; const OwnerList: TConnectionList);
const
	SomeConstValue = 600; // The line equation difference never exceeds this
begin
	Key := AKey;
	Value := AValue;
	Owner := OwnerList;
    Direction := ConnectionFlags;
	Weight := _Weight;
	NotifyNodeLocationChange();
	fIsPointOnTheEdge := function(_Point: TPoint): Boolean
	Var
		Xa, Xb, Ya, Yb: Integer;
	begin
		with Key.Point do
		begin
			Xa := X;
			Ya := Y;
		end;
		with Value.Point do
		begin
			Xb := X;
			Yb := Y;
		end;
		with _Point do
		begin
			Result := (Abs(A * X + B * Y + C) < SomeConstValue);
			Result := Result and (min(Xa, Xb) <= X) and (X <= max(Xa, Xb)) and (min(Ya, Yb) <= Y)
				and (Y <= max(Ya, Yb));
		end;
	end;
end;

destructor TConnection.Destroy;
begin
	inherited;
end;

function TConnection._GetDirection: TNodeDirection;
begin
	if Owner.GetIgnoreDirection then
    	Result := ndK2V or ndV2K
    else
    	Result := fDirection;
end;
procedure TConnection._SetDirection(Value: TNodeDirection);
begin
	fDirection := Value;
end;

procedure TConnection.NotifyNodeLocationChange();
begin
	GetLineCoefsFromTwoPoints(A, B, C);
end;

procedure TConnection.AddDirection(_From, _To: TNode; Queue: Boolean = True);
begin
	if (_From = Key) and (_To = Value) then
		Direction := Direction or ndK2V
	else if (_From = Value) and (_To = Key) then
		Direction := Direction or ndV2K;
	// We've done everything here, so it's normal again %)
end;
procedure TConnection.DelDirection(_From, _To: TNode; SelfRemove: Boolean = True);
begin
	if (_From = Key) and (_To = Value) then
		Direction := Direction and (not ndK2V)
	else
		Direction := Direction and (not ndV2K);

	if (Direction = 0) and (SelfRemove) then
		Owner.Remove(Self);
end;
procedure TConnection.SetDirection(_Key, _Value: TNode; _Direction: TNodeDirection);
begin
	if (_Key = Value) and (_Value = Key) then
	begin
		if (_Direction <> 0) and (_Direction <> ndK2V + ndV2K) then
		begin
			_Direction := (Not _Direction) and $3;
		end;
	end;

	Direction := _Direction;
end;

// ///////// //
// TNodeData //
// ///////// //
procedure TNode.Serialize(Stream: TStream);
begin
	Stream.Write(fID, sizeof(fID));
	Stream.Write(Point, sizeof(Point));
end;
procedure TNode.Deserialize(Stream: TStream);
begin
	Stream.Read(fID, sizeof(fID));
	Stream.Read(Point, sizeof(Point));
end;

constructor TNode.Create(Owner: TObjectList<TNode>);
begin
	// fAdjacVertices := TObjectList<TNode>.Create(False);
    fOwner := Owner;
end;
constructor TNode.Create(Owner: TObjectList<TNode>; _Point: TPoint);
begin
	Create(Owner);
	Point.Point := _Point;
end;
destructor TNode.Destroy;
begin
end;

function TNode.GetID: Integer;
begin
	Result := fID;
end;
procedure TNode.OnNodesListChange;
begin
	fID := fOwner.IndexOf(Self);
end;

// ////////// //
// TDataStore //
// ////////// //
constructor TDataStore.Create;
begin
	fDestroying := False;
	Nodes := TObjectList<TNode>.Create;
	Nodes.OnNotify := NotifyNodeChanges;
	Connections := TConnectionList.Create(Self);
    Connections.OnNotify := NotifyConnectionChanges;
	PendingOperations := TPendingOpList.Create(Self);
end;
destructor TDataStore.Destroy;
begin
	fDestroying := True;
	Clear;
	Nodes.Free;
	PendingOperations.Free;
	Connections.Free;
end;
procedure TDataStore.Clear;
begin
	Nodes.Clear;
	PendingOperations.Clear;
	Connections.Clear;
end;

procedure TDataStore.Serialize(Stream: TStream);
var
	I: Integer;
begin
	with Nodes do
    begin
        Stream.Write(Count, sizeof(Count));
        for I := 0 to Count - 1 do
        begin
            Items[I].Serialize(Stream);
        end;
    end;

    with Connections do
    begin
        Stream.Write(Count, sizeof(Count));
        for I := 0 to Count - 1 do
        begin
            with Items[I] do
            begin
                Stream.Write(Key.fID, sizeof(Key.fID));
                Stream.Write(Value.fID, sizeof(Value.fID));
                Stream.Write(Weight, sizeof(Weight));
                Stream.Write(fDirection, sizeof(fDirection));
            end;
        end;
    end;
end;
procedure TDataStore.Deserialize(Stream: TStream);
var
	I, Count: Integer;
	Node1ID, Node2ID: TNodeID;
	DirectionFlag, Weight: Integer;
    Node: TNode;
begin
	Stream.Read(Count, sizeof(Count));
	// First, deserialize nodes with no vertex objects
	for I := 0 to Count - 1 do
	begin
    	Node := TNode.Create(Nodes);
		Node.Deserialize(Stream);
        Nodes.Add(Node);
	end;

	Stream.Read(Count, sizeof(Count));
	for I := 0 to Count - 1 do
	begin
		Stream.Read(Node1ID, sizeof(Node1ID));
		Stream.Read(Node2ID, sizeof(Node2ID));
		Stream.Read(Weight, sizeof(Weight));
		Stream.Read(DirectionFlag, sizeof(DirectionFlag));
		Connections.Add(TConnection.Create(GetNodeByID(Node1ID), GetNodeByID(Node2ID), Weight,
			DirectionFlag, Connections));
	end;

	// Last, let them get their vertices by IDs
	// for I := 0 to Nodes.Count - 1 do
	// begin
	// Nodes[I].OnDeserializationComplete;
	// end;
end;

function TDataStore.FindItemInList(Count: Integer; GetItemProc: TGetConProc;
	VertexKey, VertexValue: TNode; _Direction: TNodeDirection = ndK2V + ndV2K;
	ORdirection: Boolean = True): Integer;
Var
	I: Integer;

	function ConditionCheck(Con: TConnection): Boolean;
	// Var
	// Cond1, Cond2: Boolean;
	begin
		// As usually _Direction is not modified (i.e. it's [ndK2V, ndV2K]),
		// we'll just search for any available connection
		with Con do
		begin
			Result := ((Key = VertexKey) and (Value = VertexValue)) or
				((Key = VertexValue) and (Value = VertexKey));
		end;
		{ with Con do
		  begin
		  if ndK2V in _Direction then
		  begin
		  Cond1 := ((Key = VertexKey) and (Value = VertexValue) and (ndK2V in Direction));
		  Cond1 := Cond1 or ((Key = VertexValue) and (Value = VertexKey) and
		  (ndV2K in Direction));
		  end;

		  if ndV2K in _Direction then
		  begin
		  Cond2 := ((Key = VertexValue) and (Value = VertexKey) and (ndK2V in Direction));
		  Cond2 := Cond2 or ((Key = VertexKey) and (Value = VertexValue) and
		  (ndV2K in Direction));
		  end;
		  end;

		  if ([ndK2V, ndV2K] = _Direction) then
		  begin
		  if ORdirection then
		  Result := Cond1 or Cond2
		  else
		  Result := Cond1 and Cond2;
		  end
		  else if ndK2V in _Direction then
		  Result := Cond1
		  else if ndV2K in _Direction then
		  Result := Cond2
		  else
		  Result := False; }

	end;

begin
	// Fucking Boolean Algebra desc:
	// We need to find an oriented arc. There're 2 cases for VertexKey -> VertexValue:
	// 1) (Key = VertexKey) and (Value = VertexValue) and the Direction is K2V (and vice-versa)
	// 2) (Key = VertexValue) and (Value = VertexKey) and the Direction is V2K (and vice-versa)
	// And there're 2 more when we'll need to find an arc if the Direction is Both:
	// 1) A node with ndBoth direction (AND condition, ORdirection = False)
	// 2) Either of two: K2V or V2K (OR condition, ORdirection = True)

	for I := 0 to Count - 1 do
	begin
		if ConditionCheck(GetItemProc(I)) then
		begin
			Result := I;
			exit;
		end;
	end;
	Result := -1;
end;

function TDataStore.LoseConnections(Node: TNode): Integer;
var
  I: Integer;
begin
    with Connections do
        for I := Count - 1 downto 0 do
        begin
            if (Items[i].Key = Node) or
               (Items[i].Value = Node)
            then
                Delete(i);
        end;
    Result := 0;
end;
function TDataStore.DeleteNode(Node: TNode): Integer;
begin
	LoseConnections(Node);
    Nodes.Remove(Node);
    Result := 0;
end;
function TDataStore.AddNode(Node: TNode): TNode;
begin
	Nodes.Add(Node);
    Result := Node;
end;
function TDataStore.FindQuery(VertexKey, VertexValue: TNode;
	_Direction: TNodeDirection = ndK2V + ndV2K; ORdirection: Boolean = True): Integer;
Var
	Proc: TGetConProc;
begin
	Proc := function(Idx: Integer): TConnection
	begin
		Result := PendingOperations[Idx].Connection;
	end;

	Result := FindItemInList(PendingOperations.Count, Proc, VertexKey, VertexValue, _Direction,
		ORdirection);
end;
function TDataStore.FindConnection(VertexKey, VertexValue: TNode;
	_Direction: TNodeDirection = ndK2V + ndV2K; ORdirection: Boolean = True): Integer;
Var
	Proc: TGetConProc;
begin
	Proc := function(Idx: Integer): TConnection
	begin
		Result := Connections[Idx];
	end;

	Result := FindItemInList(Connections.Count, Proc, VertexKey, VertexValue, _Direction,
		ORdirection);
end;

procedure TDataStore.QueueAction(Action: TConnOperation; VertexKey, VertexValue: TNode;
	_Direction: TNodeDirection; Weight: Integer);
Var
	Idx, ConIdx: Integer;
	PendingOp: TPendingOp;
begin
	Idx := FindQuery(VertexKey, VertexValue);

	if Idx = -1 then
	begin
		PendingOp := TPendingOp.Create(Self);
		with PendingOp do
		begin
			Operation := Action;
			Owner := PendingOperations;
			PO_Direction := _Direction;

			ConIdx := FindConnection(VertexKey, VertexValue);
			if ConIdx = -1 then
			begin
				// We have never been connected to that node - why unconnect it even more?
				if Action = coDelete then
				begin
					Free;
					exit;
				end;
				OwnsConnectionObj := True;
                // not nil here because of IgnoreDirection reference
				Connection := TConnection.Create(VertexKey, VertexValue, Weight, PO_Direction, Connections {nil});
			end
			else
			begin
				OwnsConnectionObj := False;
				Connection := Connections[ConIdx];
				Connection.ToBeChanged := True;

				if (VertexKey = Connection.Value) and (VertexValue = Connection.Key) then
				begin
					if (PO_Direction <> ndK2V + ndV2K) and (PO_Direction <> 0) then
						PO_Direction := (not PO_Direction) and $F; // Invert
				end;
			end;
		end;
		PendingOperations.Add(PendingOp);
	end
	else
	begin
		with PendingOperations[Idx] do
		begin
			if (_Direction and ndK2V) <> 0 then
				Connection.AddDirection(VertexKey, VertexValue);
			if (_Direction and ndV2K) <> 0 then
				Connection.AddDirection(VertexValue, VertexKey);
			Operation := Action;

			if Action = coAdd then
            	Connection.Weight := Weight;
		end;
	end;
end;
procedure TDataStore.QueryAddConnection(VertexKey, VertexValue: TNode; Direction: TNodeDirection;
	Weight: Integer);
begin
	QueueAction(coAdd, VertexKey, VertexValue, Direction, Weight);
end;
procedure TDataStore.QueryDelConnection(VertexKey, VertexValue: TNode; Direction: TNodeDirection);
begin
	QueueAction(coDelete, VertexKey, VertexValue, Direction, -1);
end;
procedure TDataStore.ApplyQueries;
var
	I: Integer;
    Op: TPendingOp;
begin
	for I := 0 to PendingOperations.Count - 1 do
	begin
        Op := PendingOperations[I];
		with Op do
		begin
			case Operation of
			coAdd:
				begin
                    with Connection do
                    begin
                        // SetDirection(Key, Value, Direction);
                        AddConnection(Key, Value, PO_Direction, Weight);
                        if OwnsConnectionObj then
                            Connection.Destroy
                        else
                            ToBeChanged := False;
                    end;
				end;
			coDelete:
				begin
                    if fLastHoveredEdge = Connection then
                        fLastHoveredEdge := nil;
                    with Connection do
                    begin
                        DelConnection(Key, Value, PO_Direction);
                        if OwnsConnectionObj then
                            Connection.Free
                        else
                            ToBeChanged := False;
                    end;
				end;
			end;
		end;
	end;
	PendingOperations.Clear;
end;

procedure TDataStore.AddConnection(VertexKey, VertexValue: TNode; Direction: TNodeDirection;
	Weight: Integer);
Var
	Idx: Integer;
begin
	Idx := FindConnection(VertexKey, VertexValue);
	if Idx = -1 then
	begin
		Connections.Add(TConnection.Create(VertexKey, VertexValue, Weight, Direction, Connections));
	end
	else
	begin
		if (Direction and ndK2V) <> 0 then
			Connections[Idx].AddDirection(VertexKey, VertexValue);
		if (Direction and ndV2K) <> 0 then
			Connections[Idx].AddDirection(VertexValue, VertexKey);
	end;
end;
procedure TDataStore.DelConnection(VertexKey, VertexValue: TNode; _Direction: TNodeDirection);
Var
	Idx: Integer;
begin
	Idx := FindConnection(VertexKey, VertexValue);
	if Idx = -1 then
		exit;
	with Connections[Idx] do
	begin
		if (_Direction and ndK2V) <> 0 then
			DelDirection(VertexKey, VertexValue, False);
		if (_Direction and ndV2K) <> 0 then
			DelDirection(VertexValue, VertexKey, False);

		if Direction = 0 then
			Connections.Delete(Idx);
	end;
end;
procedure TDataStore.DelConnection(Connection: TConnection);
begin
    Connections.Remove(Connection);
end;

procedure TDataStore.NotifyNodeChanges(Sender: TObject; const Item: TNode;
	Action: TCollectionNotification);
var
	I: Integer;
begin
	case Action of
	cnRemoved:
		begin
            for I := 0 to Nodes.Count - 1 do
            begin
                Nodes[I].OnNodesListChange;
            end;
		end;
	cnAdded:
    	begin
			Item.OnNodesListChange;
        	fLastAddedNode := Item;
        end;
	end;
end;
procedure TDataStore.NotifyConnectionChanges(Sender: TObject; const Item: TConnection;
	Action: TCollectionNotification);
begin
	case Action of
	cnRemoved:
		begin
        	if Item = fLastHoveredEdge then
				fLastHoveredEdge := nil;
		end;
	cnAdded:
		;
	end;
end;
procedure TDataStore.NotifyLocationChanges(Node: TNode);
var
	I: Integer;
begin
	for I := 0 to Connections.Count - 1 do
	begin
		with Connections[I] do
			if (Key = Node) or (Value = Node) then
			begin
				NotifyNodeLocationChange();
			end;
	end;
end;

function TDataStore.GetNodeByID(VertexID: TNodeID): TNode;
Var
	I: Integer;
begin
	for I := 0 to Nodes.Count - 1 do
		if Nodes[I].ID = VertexID then
		begin
			Result := Nodes[I];
			exit;
		end;
	Result := nil;
end;
function TDataStore.GetSelEdgeFromPoint(Point: TPoint): TConnection;
var
	I: Integer;
begin
	Result := nil;
	if (fLastHoveredEdge <> nil) then
	begin
        if (fLastHoveredEdge.IsPointOnTheEdge(Point)) then
        begin
			Result := fLastHoveredEdge;
            exit;
        end;
	end;

    for I := 0 to Connections.Count - 1 do
    begin
        if Connections[I].IsPointOnTheEdge(Point) then
        begin
            fLastHoveredEdge := Connections[I];
            Result := fLastHoveredEdge;
            break;
        end;
    end;
end;

procedure TDataStore.SetIgnoreDirection(Value: Boolean);
begin
	fIgnoreDirection := Value;
end;

end.
