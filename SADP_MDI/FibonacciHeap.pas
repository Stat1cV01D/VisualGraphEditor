unit FibonacciHeap;

interface

uses Windows;

type

	(*
	  * global heap operations
	*)

	(* Tvoidcmp = function(Item1, Item2: Pointer): Integer;

	  pPfibheap_el = ^Pfibheap_el;
	  Pfibheap_el = ^fibheap_el;
	  fibheap_el = record
	  fhe_degree,
	  fhe_mark: Integer;
	  fhe_p,
	  fhe_child,
	  fhe_left,
	  fhe_right: Pfibheap_el;
	  fhe_key: Integer;
	  fhe_data: Pointer;
	  end;

	  pfibheap = ^Tfibheap;
	  Tfibheap = record
	  fh_cmp_fnct: Tvoidcmp;
	  fh_n,
	  fh_Dl: Integer;
	  fh_cons: pPfibheap_el;
	  fh_min,
	  fh_root: Pfibheap_el;
	  fh_neginf: Pointer;
	  fh_keys: Integer;
	  {$ifdef FH_STATS}
	  fh_maxn,
	  fh_ninserts,
	  fh_nextracts: Integer;
	  {$endif}
	  end;


	  procedure fh_initheap(var Heap: Tfibheap);
	  procedure fh_insertrootlist(var Heap: Tfibheap; struct fibheap_el * );
	  procedure fh_removerootlist(var Heap: Tfibheap; struct fibheap_el * );
	  procedure fh_consolidate(struct fibheap * );
	  procedure fh_heaplink(struct fibheap *h, struct fibheap_el *y,
	  struct fibheap_el *x);
	  procedure fh_cut(struct fibheap *, struct fibheap_el *, struct fibheap_el * );
	  procedure fh_cascading_cut(struct fibheap *, struct fibheap_el * );
	  static struct fibheap_el *fh_extractminel(struct fibheap * );
	  procedure fh_checkcons(struct fibheap *h);
	  procedure fh_destroyheap(struct fibheap *h);
	  static int fh_compare(struct fibheap *h, struct fibheap_el *a,
	  struct fibheap_el *b);
	  static int fh_comparedata(struct fibheap *h, int key, void *data,
	  struct fibheap_el *b);
	  procedure fh_insertel(struct fibheap *h, struct fibheap_el *x);
	  procedure fh_deleteel(struct fibheap *h, struct fibheap_el *x);

	*)
	Tvoidcmp = function(Item1, Item2: Pointer): Integer; cdecl;

	pPfibheap_el = ^Pfibheap_el;
	Pfibheap_el = ^fibheap_el;

	fibheap_el = record
	end;

	pfibheap = ^Tfibheap;

	Tfibheap = record
	end;

{$L fib.obj}

// functions for key heaps
function _fh_makekeyheap(): pfibheap; cdecl; external;
function _fh_insertkey(Heap: pfibheap; Key: Integer; Data: Pointer): Pfibheap_el; cdecl; external;
function _fh_minkey(Heap: pfibheap): Integer; cdecl; external;
function _fh_replacekey(Heap: pfibheap; Elem: Pfibheap_el; Key: Integer): Integer; cdecl; external;
function _fh_replacekeydata(Heap: pfibheap; Elem: Pfibheap_el; Key: Integer; Data: Pointer): Pointer;
	cdecl; external;

(* functions for void * heaps *)
function _fh_makeheap(): pfibheap; cdecl; external;
function _fh_setcmp(Heap: pfibheap; Proc: Tvoidcmp): Tvoidcmp; cdecl; external;
function _fh_setneginf(Heap: pfibheap; Data: Pointer): Pointer; cdecl; external;
function _fh_insert(Heap: pfibheap; Data: Pointer): Pfibheap_el; cdecl; external;

(* shared functions *)
function _fh_extractmin(Heap: pfibheap): Pointer; cdecl; external;
function _fh_min(Heap: pfibheap): Pointer; cdecl; external;
function _fh_replacedata(Heap: pfibheap; Elem: Pfibheap_el; Data: Pointer): Pointer; cdecl; external;
function _fh_delete(Heap: pfibheap; Elem: Pfibheap_el): Pointer; cdecl; external;
procedure _fh_deleteheap(Heap: pfibheap); cdecl; external;
function _fh_union(Heap1, Heap2: pfibheap): pfibheap; cdecl; external;

{$IFDEF FH_STATS}
function _fh_maxn(Heap: pfibheap): Integer; cdecl; external;
function _fh_ninserts(Heap: pfibheap): Integer; cdecl; external;
function _fh_nextracts(Heap: pfibheap): Integer; cdecl; external;
{$ENDIF}

procedure _abort; cdecl;
procedure _free(Data: Pointer); cdecl;
function _malloc(Size: Cardinal): Pointer; cdecl;
function _realloc(Data: Pointer; Size: Cardinal): Pointer; cdecl;

implementation

function _malloc(Size: Cardinal): Pointer; cdecl;
begin
  	Result := GetMemory(Size);
end;

procedure _abort; cdecl;
begin
    Assert(False, 'Fibonacci Heap sources: abnormal termination requested!');
end;

procedure _free(Data: Pointer); cdecl;
begin
  	FreeMemory(Data);
end;

function _realloc(Data: Pointer; Size: Cardinal): Pointer; cdecl;
begin
  	Result := ReallocMemory(Data, Size);
end;

end.
