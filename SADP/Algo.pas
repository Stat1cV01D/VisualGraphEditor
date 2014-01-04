unit Algo;

interface

Uses Windows, DataStoreUnit, Generics.Collections, Generics.Defaults, Math;

// Don't make OutList own the nodes and connections
procedure GetShortestPath(DataStore: TDataStore; StartNode, EndNode: TNode);
procedure MinSpanningTree(DataStore: TDataStore);
function Maxflow		 (DataStore: TDataStore; StartNode, EndNode: TNode): integer;

implementation
uses Main, SysUtils;

type
	TConRec = record
		Con: TConnection;
		case boolean of
        True:(Weight: integer;);
        False: (Flow: Integer;);
	end;

    TWeightComparer = class(TCustomComparer<TConnection>)
		function Compare(const Left, Right: TConnection): Integer; override;
    	function Equals(const Left, Right: TConnection): Boolean; override;
    	function GetHashCode(const Value: TConnection): Integer; override;
    end;

    function TWeightComparer.Compare(const Left, Right: TConnection): Integer;
    begin
        if Left.Weight > Right.Weight then
            Result := 1
        else if Left.Weight < Right.Weight then
            Result := -1
        else
            Result := 0;
    end;

    function TWeightComparer.Equals(const Left, Right: TConnection): Boolean;
    begin
        Result := (Left.Weight = Right.Weight);
    end;

    function TWeightComparer.GetHashCode(const Value: TConnection): Integer;
    begin
        Result := Integer(@Value);
    end;
var
	WeightComparer: TWeightComparer;

procedure GetShortestPath(DataStore: TDataStore; StartNode, EndNode: TNode);
const
	infinity = MaxInt; 
Var
	i: integer;

	A: array of array of TConRec;

    VERTEXES, s, g, u, w, CurItem: integer;
	x: array of bool;
	t, h: array of integer;
begin
	// Here goes Dijkstra
	
	VERTEXES := DataStore.Nodes.Count; // Amount of nodes in the graph

	SetLength(A, VERTEXES, VERTEXES); // Initiating the matrix

	with DataStore.Connections do
		for i := 0 to Count - 1 do
		begin
			with Items[i] do
			begin
				with A[Key.ID][Value.ID] do
				begin
					Con := Items[i];
					if (Direction and ndK2V) <> 0 then
						Weight := Con.Weight;
				end;

				with A[Value.ID][Key.ID] do
				begin
					Con := Items[i];
					if (Direction and ndV2K) <> 0 then
						Weight := Con.Weight;
				end;
			end;
		end;
	// End of Matrix Initiation

	// The path is from s to g
	s := StartNode.ID; // Starting point
	g := EndNode.ID; // Ending point

	SetLength(x, VERTEXES); // Array with ones and zeroes for every node,
	// x[i]=0 - shortest path to i-th node has NOT been found yet,
	// x[i]=1 - shortest path to i-th node has been found
	SetLength(t, VERTEXES); // t[i] - the shortest path from s to i
	SetLength(h, VERTEXES); // h[i] - the node before i-th node
	// on the shortest path

	// initializing arrays
	// u=0;		    // nodes counter
	for u := 0 to VERTEXES - 1 do
	begin
		t[u] := infinity; // From the beginning all shortest paths from s to i
		// equal infinity
		x[u] := False; // and there's no shortest way for any node
	end;
	h[s] := 0; // s is the starting point, there're no nodes before it
	t[s] := 0; // The shortest path from s to s equals 0
	x[s] := True; // And there's the shortest path from s to s
	CurItem := s; // S is the current node item

	while (True) do
	begin
		// iterate thru all nodes connected with CurItem and find the shortest path for them
		for u := 0 to VERTEXES - 1 do
		begin
			if (A[CurItem][u].Weight = 0) then
				continue; // u-th node and CurItem anr not connected
			if (not x[u]) and (t[u] > t[CurItem] + A[CurItem][u].Weight) then
			// If there's no shortest path for u yet
			// and new way to u is shorter than old then
			begin
				t[u] := t[CurItem] + A[CurItem][u].Weight;
				// memorize a shorter path to array "t" and
				h[u] := CurItem; // memorize the way "CurItem->u" as the part of the path "s->u"
			end;
		end;

		// Find the shortest of all the longer ways
		w := infinity; // that's for to find the shortest way
		CurItem := -1; // At the end of the loop v will be the node with the shortest way.
		// Then it'll become the current node
		for u := 0 to VERTEXES - 1 do // Iterate thru all nodes
		begin
			if (not x[u]) and (t[u] < w) then
			// If there's no shortest path for u yet
			// and way to u is longer than the one found then
			begin
				CurItem := u; // u-th node is the current node
				w := t[u];
			end;
		end;

		if (CurItem = -1) then
		begin
			// cout<<"Нет пути из вершины "<<s<<" в вершину "<<g<<"."<<endl;
			break;
		end;

		if (CurItem = g) then // shortest path found,
		begin
			// shortest path from s to g is;
			u := g;
			while (u <> s) do
			begin
				with A[u, h[u]].Con do
				begin
					Flag := mfMarked;
					Key.Flag := mfMarked;
					Value.Flag := mfMarked;
				end;

				u := h[u];
			end;

			break;
		end;
		x[CurItem] := True;
	end;

	// Free the allocated data
	for i := 0 to VERTEXES - 1 do
		SetLength(A[i], 0);
	SetLength(A, 0);

	SetLength(x, 0);
	SetLength(t, 0);
	SetLength(h, 0);
end;

procedure MinSpanningTree(DataStore: TDataStore);
// Cruscal algo
var
	i, k: integer;
	EdgesCount, ConnectedClusterStart, NodesCount: Integer;
	Link: array of integer;// Edge connection number
	Edges: TConnectionList;
    MainClusterID: Integer;
    V_ID, K_ID: Integer;

    function GetClusterRoot(I: Integer): Integer;
    begin
    	while Link[i] <> i do
            i := Link[i];
		Result := i;
    end;
begin
	Edges := TConnectionList.Create(DataStore, WeightComparer, False);
    with DataStore do
    begin
        Edges.AddRange(Connections);
        NodesCount := Nodes.Count;
        EdgesCount := Connections.Count;
        Edges.Sort;

        SetLength(Link,NodesCount); // all the edges are in different connection clusters
        for i:=0 to NodesCount-1 do
            Link[i] := Nodes[i].ID;
    end;

	k:=NodesCount-1;
    MainClusterID := Edges[0].Key.ID;

	for i:=0 to EdgesCount - 1 do
	begin
    	if (k = 0) then
        	break;
        with Edges[i] do
        begin
        	if Weight = 0 then
            	continue;
            // if they are in different connection clusters
            if GetClusterRoot(Key.ID) <> GetClusterRoot(Value.ID) then
            begin
{$IFDEF DEBUG}
                with CoreForm.ChildWnd do
                begin
                	AddFormattedLogMsg('%d) %d, %d', [i, Key.ID, Value.ID]);
                    //GetPaused();
                end;
{$ENDIF}
                // force connection of two clusters to the MainClusterID's one
                if Link[Value.ID] = MainClusterID then
                begin
                    V_ID := GetClusterRoot(Key.ID);
                    K_ID := GetClusterRoot(Value.ID);
                end
                else
                begin
                    V_ID := GetClusterRoot(Value.ID);
                    K_ID := GetClusterRoot(Key.ID);
                end;

                Link[V_ID] := K_ID;

                Flag := mfMarked;
                Value.Flag := mfMarked;
                Key.Flag := mfMarked;
                Dec(k);
            end;
        end;
     end;
     SetLength(Link, 0);
     Edges.Free;
end;


type
	IntMatrix = array of array of TConRec;

// bfs: Broad First Search for Ford-Fulkerson method
// Returns true, if there exists path from s to t
// p - hold path from previous vertices
function bfs(f, c: IntMatrix; s, t: integer; var p: TList<Integer>): boolean;
var
  i, j: Integer;
  q: TQueue<Integer>;
  v: array of Boolean;
  n: Integer;
begin
  n := Length(f[0]); // = Length(c[0]);

  SetLength(v, n);        				// initializing "visited" array
  q := TQueue<Integer>.Create;
  q.Enqueue(s);                  		// Enqueue the Source
  v[s] := True;                         // Source is visited
  p[s] := -1;                           // and has no previous vertex

  while q.Count <> 0 do        			// while the queue is not empty
  begin
    i := q.Dequeue;             		// get the vertex
    for j := 0 to n-1 do                // enum all the vertices now
      if not v[j] and                   // vertex is not visited
        (c[i, j].Flow-f[i, j].Flow > 0) then // edge i->j is not saturated
      begin
        v[j] := True;                   // j is now visited
        q.Enqueue(j);            		// j is now enqueued
        p[j] := i;                      // i is a parent for j
      end;
  end;
  Result := v[t];                       // Is Destination reached?
  SetLength(v, 0);
  q.Free;
end;


{ maxflow: Maximum flow values }
{ Matrix f holds flow values, s-source, t-destination }
function Maxflow(DataStore: TDataStore; StartNode, EndNode: TNode): integer;
const
	infinity = MaxInt; 
var
  k, start, _end: integer;
  d, flow: integer;
  p: TList<Integer>;
  f, c: IntMatrix;
  I: Integer;
begin
    with DataStore do
    begin
        with Nodes do
        begin
            SetLength(f, Count, Count);
            SetLength(c, Count, Count);
        end;

        with Connections do
        begin
            for I := 0 to Count - 1 do
            begin
                with Items[i] do
                begin
                    if (Direction and ndK2V) <> 0 then
                        with c[Key.ID, Value.ID] do
                         	Flow := Items[i].Weight;

                    if (Direction and ndV2K) <> 0 then
                    	with c[Value.ID, Key.ID] do
                        	Flow := Items[i].Weight;

                    f[Value.ID, Key.ID].Con := Items[i];
                    f[Key.ID, Value.ID].Con := Items[i];
                end;
            end;
        end;
    end;

    flow := 0;                            		// max flow is 0

    start := StartNode.ID;
    _end  := EndNode.ID;

    p := TList<Integer>.Create;
    p.Count := DataStore.Nodes.Count;

    while bfs(f, c, start, _end, p) do          // while path from s to t exists
    begin                                 		// as we come to the destination
    											// in the resudual matrix, we search
        d := infinity;                      	// for the edge with minimal
        k := _end;                          	// unused flow value
        while k <> start do
        begin
          	d := min(d, c[p[k], k].Flow-f[p[k], k].Flow);
          	k := p[k];                        	// get parent vertex
        end;

        k := _end;                          	// now going from destination
        while k <> start do                 	// to source
        begin
          	f[p[k], k].Flow := f[p[k], k].Flow + d;     	// increasing the direct flow
          	f[k, p[k]].Flow := f[k, p[k]].Flow - d;     	// decreasing the reverted flow
            with f[p[k], k].Con do
            begin
            	Flow := f[p[k], k].Flow;
                Flag := mfMarked;
                Key.Flag := mfMarked;
                Value.Flag := mfMarked;
            end;
            k := p[k];                        	// get parent vertex
        end;

        flow := flow + d;                   	// increase the overall flow
    end;
    p.Free;

    with DataStore.Nodes do
        for I := 0 to Count - 1 do
        begin
            SetLength(f[i], 0);
            SetLength(c[i], 0);
        end;
    SetLength(f, 0);
	SetLength(c, 0);

    Result := flow;                      		// return max flow value
end;

initialization
	WeightComparer := TWeightComparer.Create;

finalization
    WeightComparer.Free;
end.
