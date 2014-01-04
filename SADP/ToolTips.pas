unit ToolTips;

(*******************************************************************************

  Tool tips API Wrapper - allow to manage the tool tips easily

  Programmed by Leonid Lebedev <lebedevlp@mail.ru>, all rights reserved
  Fixed and improved by Samuel Soldat <samuel.soldat@snafu.de>, see SSyymmdd
  Any bug reports and improvement suggestions are welcomed
  Please do have respect for the copyright and do not change this header

  Last update: 13 March 2011

*******************************************************************************)

interface

uses
  SysUtils, Windows, Messages, Graphics, Classes, Controls, CommCtrl;

const
  TTN_GETDISPINFO = (TTN_FIRST - 0);
  TTN_SHOW = (TTN_FIRST - 1);
  TTN_POP = (TTN_FIRST - 2);
  TTN_LINKCLICK = (TTN_FIRST - 3);

  TTID_AUTO = 0;

type
  // An application-defined function that processes messages sent to a window.
  // To explain STRICT in detail see Remarks section of CallWindowProc function.
  {$IFDEF STRICT}
  TWndProc = function(
    hwnd: THandle; {handle of window}
    uMsg: Longword; {message identifier}
    wParam: Longint; {first message parameter}
    lParam: Longint {second message parameter}
  ): Longint; stdcall;
  {$ELSE}
  TWndProc = TFarProc;
  {$ENDIF}

  // Contains information used in handling the TTN_GETDISPINFO notification
  // message.
  TTTNGetDispInfo = packed record
    Msg: Cardinal;
    idCtrl: Longint;
    lpnmtdi: PNMTTDispInfo;
    Result: Longint;
  end;
  TTTNLinkClick = TWMNoParams;
  // Contains information about a notification message.
  TTTNPop = packed record
    Msg: Cardinal;
    idTT: Longint;
    pnmh: PNMHdr;
    Result: Longint;
  end;
  TTTNShow = TTTNPop;

  TToolTipStyle = (ttsAlwaysTip, ttsBalloon, ttsNoAnimate, ttsNoFade,
    ttsNoPrefix, ttsClose, ttsUseVisualStyle);
  TToolTipStyles = set of TToolTipStyle;

  TOnTTGetDispInfo = procedure(
    Sender: TObject;
    var DispInfo: TNMTTDispInfo
  ) of object;
  TOnTTLinkClick = TNotifyEvent;
  TOnTTPop = procedure(
    Sender: TObject;
    Id: Integer;
    const Header: TNMHdr
  ) of object;
  TOnTTShow = TOnTTPop;

  // Lightweight window control class for the tool tips usage.
  TToolTipWindow = class
  private
    fHandle: THandle;
    fParent: TWinControl;
    fWndProcPtr: Pointer;
    fPrevWndProc: Pointer;
    fOnGetDispInfo: TOnTTGetDispInfo;
    fOnLinkClick: TOnTTLinkClick;
    fOnPop: TOnTTPop;
    fOnShow: TOnTTShow;
    fStyles: TToolTipStyles;
    function GetStyles: TToolTipStyles;
  protected
    procedure WndProc(var Msg: TMessage); virtual;

    // Creates an overlapped, pop-up, or child window with an extended window
    // style.
    class function Window_CreateEx(dwExStyle: Longword; lpClassName: PAnsiChar;
      lpWindowName: PAnsiChar; dwStyle: Longword; x, y: Integer;
      nWidth, nHeight: Integer; hWndParent: THandle; hMenu: THandle;
      lpParam: Pointer): THandle;
    // Retrieves information about the specified window.
    class function Window_GetLong(hWnd: THandle; nIndex: Integer): Longint;
    // Changes an attribute of the specified window.
    class function Window_SetLong(hWnd: THandle; nIndex: Integer;
      dwNewLong: Longint): Longint;
    // Changes the size, position, and Z order of a child, pop-up, or top-level
    // window.
    class function Window_SetPos(hWnd: THandle; hWndInsertAfter: THandle;
      x, y: Integer; nWidth, nHeight: Integer; uFlags: Longword): Boolean;
    // Passes message information to the specified window procedure.
    class function Window_CallProc(lpPrevWndFunc: TWndProc; hWnd: THandle;
      Msg: Longword; wParam: Longint; lParam: Longint): Longint;

    // Sent when a window is being destroyed.
    procedure WMDestroy(var Message: TWMDestroy);
    // Sent by a common control to its parent window when an event has occurred
    // or the control requires some information.
    // SS110312: WMNotify now returns result
    function WMNotify(var Message: TWMNotify): Boolean;

    // Sent by a ToolTip control to retrieve information needed to display a
    // ToolTip window. This notification is sent in the form of a WM_NOTIFY
    // message.
    procedure TTNGetDispInfo(var Message: TTTNGetDispInfo); virtual;
    // Sent when a text link inside a balloon ToolTip is clicked.
    procedure TTNLinkClick(var Message: TTTNLinkClick); virtual;
    // Notifies the owner window that a ToolTip is about to be hidden. This
    // notification message is sent in the form of a WM_NOTIFY message.
    procedure TTNPop(var Message: TTTNPop); virtual;
    // Notifies the owner window that a ToolTip control is about to be
    // displayed. This notification message is sent in the form of a WM_NOTIFY
    // message.
    procedure TTNShow(var Message: TTTNShow); virtual;

    function GetWindowExStyle: Longword; virtual;
    function GetWindowClassName: PAnsiChar; virtual;
    function GetWindowStyle: Longword; virtual;
  public
    constructor Create(AParent: TWinControl); virtual;
    constructor CreateStyled(AParent: TWinControl; AStyles: TToolTipStyles);
    procedure AfterConstruction; override;
    property Handle: THandle read fHandle;
    property Parent: TWinControl read fParent;
    property Styles: TToolTipStyles read GetStyles;
    property OnGetDispInfo: TOnTTGetDispInfo read fOnGetDispInfo write fOnGetDispInfo;
    property OnLinkClick: TOnTTLinkClick read fOnLinkClick write fOnLinkClick;
    property OnPop: TOnTTPop read fOnPop write fOnPop;
    property OnShow: TOnTTShow read fOnShow write fOnShow;
  end;

  // Provides information about the title of a tooltip control.
  TTTGetTitleA = packed record
    dwSize: Longword; {size of structure}
    uTitleBitmap: Longword; {the tooltip icon}
    cch: Longword; {the number of characters in the title}
    pszTitle: PAnsiChar; {pointer to a multibyte string that contains the title}
  end;
  TTTGetTitleW = packed record
    dwSize: Longword; {size of structure}
    uTitleBitmap: Longword; {the tooltip icon}
    cch: Longword; {the number of characters in the title}
    pszTitle: PWideChar; {pointer to a wide string that contains the title}
  end;
  {$IFDEF UNICODE}
  TTTGetTitle = TTTGetTitleW;
  {$ELSE}
  TTTGetTitle = TTTGetTitleA;
  {$ENDIF}
  PTTGetTitle = ^TTTGetTitle;

  TToolTipIcon = (ttiNone, ttiInfo, ttiWarning, ttiError, ttiInfoLarge,
    ttiWarningLarge, ttiErrorLarge);

  TToolTipFlag = (ttfAbsolute, ttfCenterTip, ttfIdIsHWND, ttfParseLinks,
    ttfRTLReading, ttfSubClass, ttfTrack, ttfTransparent);
  TToolTipFlags = set of TToolTipFlag;

  TToolTip = class;
  TToolTipControl = class(TToolTipWindow)
  private
    // SS110312: Use TList instead of TObjectList so uses Contnrs obsoleted
    fToolTips: TList;
    fInfo: TTTGetTitle;
    // SS110312: fInfo.pszTitle will refer to fTitle so GetTitle obsoleted
    fTitle: string;
    fFlagsToInclude: TToolTipFlags;
    fFlagsToExclude: TToolTipFlags;
    function GetAutoPopTime: Cardinal;
    procedure SetAutoPopTime(const Value: Cardinal);
    function GetInitialTime: Cardinal;
    procedure SetInitialTime(const Value: Cardinal);
    function GetReshowTime: Cardinal;
    procedure SetReshowTime(const Value: Cardinal);
    function GetMargin: TRect;
    procedure SetMargin(const Value: TRect);
    function GetLeftMargin: Integer;
    procedure SetLeftMargin(const Value: Integer);
    function GetTopMargin: Integer;
    procedure SetTopMargin(const Value: Integer);
    function GetRightMargin: Integer;
    procedure SetRightMargin(const Value: Integer);
    function GetBottomMargin: Integer;
    procedure SetBottomMargin(const Value: Integer);
    function GetMaxTipWidth: Integer;
    procedure SetMaxTipWidth(const Value: Integer);
    function GetBackColor: TColor;
    procedure SetBackColor(const Value: TColor);
    function GetTextColor: TColor;
    procedure SetTextColor(const Value: TColor);
    function GetIcon: TToolTipIcon;
    procedure SetIcon(const Value: TToolTipIcon);
    procedure SetTitle(const Value: string);
    function GetItem(const Index: Integer): TToolTip;
    function GetCount: Integer;
    function GetCurrentTool: TToolInfo;
    function GetCurrentToolExists: Boolean;
    function GetTool(iTool: Cardinal): TToolInfo;
    function GetToolCount: Integer;
  protected
    // Registers specific common control classes from the common control DLL.
    class function CommonControls_InitEx(dwICC: Longword): Boolean;

    procedure TTNGetDispInfo(var Message: TTTNGetDispInfo); override;
    procedure TTNLinkClick(var Message: TTTNLinkClick); override;
    procedure TTNPop(var Message: TTTNPop); override;
    procedure TTNShow(var Message: TTTNShow); override;

    procedure AfterAdjustRect(var ARect: TRect); virtual;

    function EnumTools(iTool: Longword; var AInfo: TToolInfo): Boolean; virtual;
    function HitTest(APoint: TPoint; var AInfo: TToolInfo): Boolean; virtual;

    property Tools[iTool: Cardinal]: TToolInfo read GetTool;
    property Margin: TRect read GetMargin write SetMargin;
    property CurrentToolExists: Boolean read GetCurrentToolExists;
    property CurrentTool: TToolInfo read GetCurrentTool;
    property ToolCount: Integer read GetToolCount;
  public
    // NOTICE: Control destruction will remove all the tool tips owned.
    constructor Create(AParent: TWinControl); override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function Add(AToolTip: TToolTip): Integer; virtual;
    // NOTICE: Remove will destroy AToolTip.
    function Remove(AToolTip: TToolTip): Integer; virtual;
    procedure Activate;
    procedure Deactivate;
    function AdjustTextRect(var ARect: TRect): Boolean;
    function AdjustWindowRect(var ARect: TRect): Boolean;
    // Set all three delay times to default proportions.
    procedure SetAutomaticDelayTime;
    procedure Pop;
    procedure Popup;
    procedure RelayEvent(var Msg: TMsg);
    // SS110312: ATheme is a constant parameter now
    procedure SetWindowTheme(const ATheme: string);
    procedure TrackPosition(X, Y: Word);
    procedure Update;
    function WindowFromPoint(APoint: TPoint): THandle;
    // SS110312: AddHints add tool tips according Hint properties from AControl
    //           and all of its children recursively
    procedure AddHints(AControl: TControl);
    // The amount of time a ToolTip window remains visible if the pointer is
    // stationary within a tool's bounding rectangle.
    property AutoPopTime: Cardinal read GetAutoPopTime write SetAutoPopTime;
    // The amount of time a pointer must remain stationary within a tool's
    // bounding rectangle before the ToolTip window appears.
    property InitialTime: Cardinal read GetInitialTime write SetInitialTime;
    // The amount of time it takes for subsequent ToolTip windows to appear as
    // the pointer moves from one tool to another.
    property ReshowTime: Cardinal read GetReshowTime write SetReshowTime;
    property LeftMargin: Integer read GetLeftMargin write SetLeftMargin;
    property TopMargin: Integer read GetTopMargin write SetTopMargin;
    property RightMargin: Integer read GetRightMargin write SetRightMargin;
    property BottomMargin: Integer read GetBottomMargin write SetBottomMargin;
    property MaxTipWidth: Integer read GetMaxTipWidth write SetMaxTipWidth;
    property BackColor: TColor read GetBackColor write SetBackColor;
    property TextColor: TColor read GetTextColor write SetTextColor;
    property Icon: TToolTipIcon read GetIcon write SetIcon;
    property Title: string read fTitle write SetTitle;
    property Items[const Index: Integer]: TToolTip read GetItem; default;
    property Count: Integer read GetCount;
  end;

  TStandardToolTipControl = class(TToolTipControl)
  public
    constructor Create(AParent: TWinControl); override;
  end;

  TTrackingToolTipControl = class(TToolTipControl)
  public
    constructor Create(AParent: TWinControl); override;
  end;

  TMultilineToolTipControl = class(TStandardToolTipControl)
  public
    constructor Create(AParent: TWinControl); override;
  end;

  TBalloonToolTipControl = class(TToolTipControl)
  public
    constructor Create(AParent: TWinControl); override;
  end;

  TInPlaceToolTipControl = class(TStandardToolTipControl)
  protected
    procedure AfterAdjustRect(var ARect: TRect); override;
  end;

  TToolTipId = Longword;

  TOnToolTipGetDispInfo = function(
    Sender: TObject;
    var Instance: THandle;
    var ResName: string;
    var Text: string;
    Data: Longint
  ): Boolean of object;
  TOnToolTipLinkClick = TNotifyEvent;
  TOnToolTipPop = TNotifyEvent;
  TOnToolTipShow = TOnToolTipPop;

  TToolTip = class
  private
    fOwner: TToolTipControl;
    fControl: TControl;
    fParent: TWinControl;
    fInfo: TToolInfo;
    // SS110312: fInfo.lpszText will refer to fText so GetText obsoleted
    fText: string;
    fTrackActivated: Boolean;
    fOnGetDispInfo: TOnToolTipGetDispInfo;
    fOnLinkClick: TOnToolTipLinkClick;
    fOnPop: TOnToolTipPop;
    fOnShow: TOnToolTipShow;
    procedure SetOwner(const Value: TToolTipControl);
    procedure SetControl(const Value: TControl);
    function GetId: TToolTipId;
    function GetFlags: TToolTipFlags;
    procedure SetFlags(const Value: TToolTipFlags);
    function GetClipRect: TRect;
    procedure SetText(const Value: string);
    function GetBubbleSize: TSize;
    function GetToolInfo: TToolInfo;
  protected
    class function GetWinControl(AControl: TControl): TWinControl;

    function DoGetDispInfo(var Instance: THandle; var ResName: string;
      var Text: string; Data: Longint): Boolean; virtual;
    procedure DoLinkClick; virtual;
    procedure DoPop; virtual;
    procedure DoShow; virtual;

    procedure CheckOwner(const MethodName: string);

    function AddTool: Boolean; virtual;
    procedure DelTool; virtual;
    procedure SetInfo(const Value: TToolInfo); virtual;

    property ToolInfo: TToolInfo read GetToolInfo;
  public
    constructor Create(AControl: TControl; const GetDispInfo: Boolean = False;
       AId: TToolTipId = TTID_AUTO); virtual;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure SetClipRect(const Value: TRect); overload;
    procedure SetClipRect(AControl: TControl; const Value: TRect); overload;
    procedure NewToolRect(const ARect: TRect);
    procedure TrackActivate;
    procedure TrackDisactivate;
    procedure TrackPosition(X, Y: Word);
    property Owner: TToolTipControl read fOwner write SetOwner;
    property Control: TControl read fControl write SetControl;
    property Parent: TWinControl read fParent;
    property Id: TToolTipId read GetId;
    property Flags: TToolTipFlags read GetFlags write SetFlags;
    property ClipRect: TRect read GetClipRect;
    // NOTICE: GetBubbleSize will return zeroes if called before TrackActivate.
    property BubbleSize: TSize read GetBubbleSize;
    property Text: string read fText write SetText;
    property OnGetDispInfo: TOnToolTipGetDispInfo read fOnGetDispInfo write fOnGetDispInfo;
    property OnLinkClick: TOnToolTipLinkClick read fOnLinkClick write fOnLinkClick;
    property OnPop: TOnToolTipPop read fOnPop write fOnPop;
    property OnShow: TOnToolTipShow read fOnShow write fOnShow;
  end;

  EToolTip = class(Exception);

implementation

uses Types;

resourcestring
  S_EWin32Error = 'Win32 API call of %s failed'#13#10'Error code %d (%s)';
  S_EUnkWin32Error = 'Win32 API call of %s failed'#13#10'Error code %d';
  S_ENotSupported = 'This kind of the tool tips is not supported';
  S_EMessage = 'Error sending message %s';
  S_ECheckOwner = 'Call of %s.%s failed due to ToolTip has no owner window';
  S_ENoWindow = 'Control %s: %s has no parent window';
  S_EId = 'Invalid tool id %d';
  S_ESetText = 'Unable to set ToolTip text due to GetDispInfo was TRUE';

procedure RaiseLastWin32Error(const FunctionName: string);
{$IFNDEF SUPPRESS_WIN32ERROR}
var
  LastError: DWORD;
  Error: EOSError;
{$ENDIF}
begin
  {$IFNDEF SUPPRESS_WIN32ERROR}
  LastError := GetLastError;
  if LastError <> ERROR_SUCCESS then
    Error := EOSError.CreateFmt(S_EWin32Error,
      [FunctionName, LastError, SysErrorMessage(LastError)])
  else
    Error := EOSError.CreateFmt(S_EUnkWin32Error,
      [FunctionName, LastError]);
  Error.ErrorCode := LastError;
  raise Error;
  {$ENDIF}
end;

procedure RaiseToolTipError(const MessageName: string);
begin
  {$IFNDEF SUPPRESS_TOOLTIPERROR}
  raise EToolTip.CreateFmt(S_EMessage, [MessageName]);
  {$ENDIF}
end;

const
  CCM_SETWINDOWTHEME = (CCM_FIRST + $0B);
  TTF_PARSELINKS = $1000;
  TTM_GETBUBBLESIZE = (WM_USER + 30);
  TTM_ADJUSTRECT = (WM_USER + 31);
  {$IFDEF UNICODE}
  TTM_SETTITLE = (WM_USER + 33);
  {$ELSE}
  TTM_SETTITLE = (WM_USER + 32);
  {$ENDIF}
  TTM_POPUP = (WM_USER + 34);
  TTM_GETTITLE = (WM_USER + 35);
  TTM_SETWINDOWTHEME = CCM_SETWINDOWTHEME;
  TTS_BALLOON = $40;

type
  ToolTipsAPI = class
  protected
    // Activates or deactivates a ToolTip control.
    class procedure Activate(hWndControl: THandle; fActivate: Boolean);
    // Registers a tool with a ToolTip control.
    // Returns TRUE if successful, or FALSE otherwise.
    class function Add(hWndControl: THandle; lpti: PToolInfo): Boolean;
    // Calculates a ToolTip control's text display rectangle from its window
    // rectangle, or the ToolTip window rectangle needed to display a specified
    // text display rectangle.
    // Returns a non-zero value if the rectangle is successfully adjusted, and
    // returns zero if an error occurs.
    class function AdjustRect(hWndControl: THandle; fLarger: Boolean; prc: PRect): Longint;
    // Removes a tool from a ToolTip control.
    class procedure Del(hWndControl: THandle; lpti: PToolInfo);
    // Retrieves the information that a ToolTip control maintains about the
    // current tool—that is, the tool for which the ToolTip is currently
    // displaying text.
    // Returns TRUE if any tools are enumerated, or FALSE otherwise.
    class function Enum(hWndControl: THandle; iTool: Longword; lpti: PToolInfo): Boolean;
    // Returns the width and height of a ToolTip control.
    // Returns the width of the ToolTip in the low word and the height in the
    // high word if successful. Otherwise, it returns FALSE.
    class function GetBubbleSize(hWndControl: THandle; pTtm: PToolInfo): Longint;
    // Retrieves the information for the current tool in a ToolTip control.
    // Returns nonzero if successful, or zero otherwise. If lpti is NULL,
    // returns nonzero if a current tool exists, or zero otherwise.
    class function GetCurrent(hWndControl: THandle; lpti: PToolInfo): Longint;
    // Retrieves the initial, pop-up, and reshow durations currently set for a
    // ToolTip control.
    // Returns and INT value with the specified duration in milliseconds.
    class function GetDelayTime(hWndControl: THandle; dwDuration: Longword): Integer;
    // Retrieves the top, left, bottom, and right margins set for a ToolTip
    // window. A margin is the distance, in pixels, between the ToolTip window
    // border and the text contained within the ToolTip window.
    class procedure GetMargin(hWndControl: THandle; lprc: PRect);
    // Retrieves the maximum width for a ToolTip window.
    // Returns an INT value that represents the maximum ToolTip width, in
    // pixels. If no maximum width was set previously, the message returns -1.
    class function GetMaxWidth(hWndControl: THandle): Integer;
    // Retrieves the information a ToolTip control maintains about a tool.
    class procedure GetText(hWndControl: THandle; wNumber: Longint; lpti: PToolInfo);
    // Retrieves the background color in a ToolTip window.
    // Returns a Longword value that represents the background color.
    class function GetBkColor(hWndControl: THandle): Longword;
    // Retrieves the text color in a ToolTip window.
    // Returns a Longword value that represents the text color.
    class function GetTextColor(hWndControl: THandle): Longword;
    // Retrieve information concerning the title of a toolTip control.
    class procedure GetTitle(hWndControl: THandle; pGetTitle: PTTGetTitle);
    // Retrieves a count of the tools maintained by a ToolTip control.
    // Returns a count of tools.
    class function GetCount(hWndControl: THandle): Longint;
    // Retrieves the information that a ToolTip control maintains about a tool.
    // Returns TRUE if successful, or FALSE otherwise.
    class function GetInfo(hWndControl: THandle; lpti: PToolInfo): Boolean;
    // Tests a point to determine whether it is within the bounding rectangle of
    // the specified tool and, if it is, retrieves information about the tool.
    // Returns TRUE if the tool occupies the specified point, or FALSE
    // otherwise.
    class function HitTest(hWndControl: THandle; lphti: PTTHitTestInfo): Boolean;
    // Sets a new bounding rectangle for a tool.
    class procedure NewRect(hWndControl: THandle; lpti: PToolInfo);
    // Removes a displayed ToolTip window from view.
    class procedure Pop(hWndControl: THandle);
    // Causes the ToolTip to display at the coordinates of the last mouse
    // message.
    class procedure Popup(hWndControl: THandle);
    // Passes a mouse message to a ToolTip control for processing.
    class procedure RelayEvent(hWndControl: THandle; lpmsg: PMsg);
    // Sets the initial, pop-up, and reshow durations for a ToolTip control.
    class procedure SetDelayTime(hWndControl: THandle; dwDuration: Word; iTime: Longword);
    // Sets the top, left, bottom, and right margins for a ToolTip window. A
    // margin is the distance, in pixels, between the ToolTip window border and
    // the text contained within the ToolTip window.
    class procedure SetMargin(hWndControl: THandle; lprc: PRect);
    // Sets the maximum width for a ToolTip window.
    // Returns the previous maximum ToolTip width.
    class function SetMaxWidth(hWndControl: THandle; iWidth: Integer): Longint;
    // Sets the background color in a ToolTip window.
    class procedure SetBkColor(hWndControl: THandle; clr: Longword);
    // Sets the text color in a ToolTip window.
    class procedure SetTextColor(hWndControl: THandle; clr: Longword);
    // Adds a standard icon and title string to a ToolTip.
    // Returns TRUE if successful, FALSE if not.
    {$IFDEF UNICODE}
    class function SetTitle(hWndControl: THandle; icon: Integer; pszTitle: PWideChar): Boolean;
    {$ELSE}
    class function SetTitle(hWndControl: THandle; icon: Integer; pszTitle: PAnsiChar): Boolean;
    {$ENDIF}
    // Sets the information that a ToolTip control maintains for a tool.
    class procedure SetInfo(hWndControl: THandle; lpti: PToolInfo);
    // Sets the visual style of a ToolTip control.
    class procedure SetWindowTheme(hWndControl: THandle; pwStr: PWideChar);
    // Activates or deactivates a tracking ToolTip.
    class procedure TrackActivate(hWndControl: THandle; bActivate: Boolean; lpti: PToolInfo);
    // Sets the position of a tracking ToolTip.
    class procedure TrackPosition(hWndControl: THandle; xPos, yPos: Word);
    // Forces the current tool to be redrawn.
    class procedure Update(hWndControl: THandle);
    // Sets the ToolTip text for a tool.
    class procedure UpdateText(hWndControl: THandle; lpti: PToolInfo);
    // Allows a subclass procedure to cause a ToolTip to display text for a
    // window other than the one beneath the mouse cursor.
    // The return value is the handle to the window that contains the point, or
    // NULL if no window exists at the specified point.
    class function WindowFromPoint(hWndControl: THandle; lppt: PPoint): Longint;
  end;

{ ToolTipsAPI }

class procedure ToolTipsAPI.Activate(hWndControl: THandle;
  fActivate: Boolean);
begin
  SendMessage(hWndControl, TTM_ACTIVATE, Integer(fActivate), 0);
end;

class function ToolTipsAPI.Add(hWndControl: THandle;
  lpti: PToolInfo): Boolean;
begin
  Result := SendMessage(hWndControl, TTM_ADDTOOL, 0, Integer(lpti)) <> 0;
  if not Result then
    RaiseToolTipError('TTM_ADDTOOL');
end;

class function ToolTipsAPI.AdjustRect(hWndControl: THandle;
  fLarger: Boolean; prc: PRect): Longint;
begin
  Result := SendMessage(hWndControl, TTM_ADJUSTRECT, Integer(fLarger), Integer(prc));
  if Result = 0 then
    RaiseToolTipError('TTM_ADJUSTRECT');
end;

class procedure ToolTipsAPI.Del(hWndControl: THandle; lpti: PToolInfo);
begin
  SendMessage(hWndControl, TTM_DELTOOL, 0, Integer(lpti));
end;

class function ToolTipsAPI.Enum(hWndControl: THandle; iTool: Longword;
  lpti: PToolInfo): Boolean;
begin
  Result := SendMessage(hWndControl, TTM_ENUMTOOLS, iTool, Integer(lpti)) <> 0;
  if not Result then
    RaiseToolTipError('TTM_ENUMTOOLS');
end;

class function ToolTipsAPI.GetBkColor(hWndControl: THandle): Longword;
begin
  Result := SendMessage(hWndControl, TTM_GETTIPBKCOLOR, 0, 0);
end;

class function ToolTipsAPI.GetBubbleSize(hWndControl: THandle;
  pTtm: PToolInfo): Longint;
begin
  Result := SendMessage(hWndControl, TTM_GETBUBBLESIZE, 0, Integer(pTtm));
  if Result = 0 then
    RaiseToolTipError('TTM_GETBUBBLESIZE');
end;

class function ToolTipsAPI.GetCount(hWndControl: THandle): Longint;
begin
  Result := SendMessage(hWndControl, TTM_GETTOOLCOUNT, 0, 0);
end;

class function ToolTipsAPI.GetCurrent(hWndControl: THandle;
  lpti: PToolInfo): Longint;
begin
  Result := SendMessage(hWndControl, TTM_GETCURRENTTOOL, 0, Integer(lpti));
  if Result = 0 then
    RaiseToolTipError('TTM_GETCURRENTTOOL');
end;

class function ToolTipsAPI.GetDelayTime(hWndControl: THandle;
  dwDuration: Longword): Integer;
begin
  Result := SendMessage(hWndControl, TTM_GETDELAYTIME, dwDuration, 0)
end;

class function ToolTipsAPI.GetInfo(hWndControl: THandle;
  lpti: PToolInfo): Boolean;
begin
  Result := SendMessage(hWndControl, TTM_GETTOOLINFO, 0, Integer(lpti)) <> 0;
  if not Result then
    RaiseToolTipError('TTM_GETTOOLINFO');
end;

class procedure ToolTipsAPI.GetMargin(hWndControl: THandle; lprc: PRect);
begin
  SendMessage(hWndControl, TTM_GETMARGIN, 0, Integer(lprc));
end;

class function ToolTipsAPI.GetMaxWidth(hWndControl: THandle): Integer;
begin
  Result := SendMessage(hWndControl, TTM_GETMAXTIPWIDTH, 0, 0);
end;

class procedure ToolTipsAPI.GetText(hWndControl: THandle; wNumber: Integer;
  lpti: PToolInfo);
begin
  SendMessage(hWndControl, TTM_GETTEXT, wNumber, Integer(lpti));
end;

class function ToolTipsAPI.GetTextColor(hWndControl: THandle): Longword;
begin
  Result := SendMessage(hWndControl, TTM_GETTIPTEXTCOLOR, 0, 0);
end;

class procedure ToolTipsAPI.GetTitle(hWndControl: THandle;
  pGetTitle: PTTGetTitle);
begin
  SendMessage(hWndControl, TTM_GETTITLE, 0, Integer(pGetTitle));
end;

class function ToolTipsAPI.HitTest(hWndControl: THandle;
  lphti: PTTHitTestInfo): Boolean;
begin
  Result := SendMessage(hWndControl, TTM_HITTEST, 0, Integer(lphti)) <> 0;
end;

class procedure ToolTipsAPI.NewRect(hWndControl: THandle; lpti: PToolInfo);
begin
  SendMessage(hWndControl, TTM_NEWTOOLRECT, 0, Integer(lpti));
end;

class procedure ToolTipsAPI.Pop(hWndControl: THandle);
begin
  SendMessage(hWndControl, TTM_POP, 0, 0);
end;

class procedure ToolTipsAPI.Popup(hWndControl: THandle);
begin
  SendMessage(hWndControl, TTM_POPUP, 0, 0);
end;

class procedure ToolTipsAPI.RelayEvent(hWndControl: THandle; lpmsg: PMsg);
begin
  SendMessage(hWndControl, TTM_RELAYEVENT, 0, Integer(lpmsg));
end;

class procedure ToolTipsAPI.SetBkColor(hWndControl: THandle;
  clr: Longword);
begin
  SendMessage(hWndControl, TTM_SETTIPBKCOLOR, clr, 0);
end;

class procedure ToolTipsAPI.SetDelayTime(hWndControl: THandle;
  dwDuration: Word; iTime: Longword);
begin
  SendMessage(hWndControl, TTM_SETDELAYTIME, dwDuration, iTime);
end;

class procedure ToolTipsAPI.SetInfo(hWndControl: THandle; lpti: PToolInfo);
begin
  SendMessage(hWndControl, TTM_SETTOOLINFO, 0, Integer(lpti));
end;

class procedure ToolTipsAPI.SetMargin(hWndControl: THandle; lprc: PRect);
begin
  SendMessage(hWndControl, TTM_SETMARGIN, 0, Integer(lprc));
end;

class function ToolTipsAPI.SetMaxWidth(hWndControl: THandle;
  iWidth: Integer): Longint;
begin
  Result := SendMessage(hWndControl, TTM_SETMAXTIPWIDTH, 0, iWidth);
end;

class procedure ToolTipsAPI.SetTextColor(hWndControl: THandle;
  clr: Longword);
begin
  SendMessage(hWndControl, TTM_SETTIPTEXTCOLOR, clr, 0);
end;

{$IFDEF UNICODE}
class function ToolTipsAPI.SetTitle(hWndControl: THandle; icon: Integer;
  pszTitle: PWideChar): Boolean;
{$ELSE}
class function ToolTipsAPI.SetTitle(hWndControl: THandle; icon: Integer;
  pszTitle: PAnsiChar): Boolean;
{$ENDIF}
begin
  Result := SendMessage(hWndControl, TTM_SETTITLE, icon, Integer(pszTitle)) <> 0;
  if not Result then
    RaiseToolTipError('TTM_SETTITLE');
end;

class procedure ToolTipsAPI.SetWindowTheme(hWndControl: THandle;
  pwStr: PWideChar);
begin
  SendMessage(hWndControl, TTM_SETWINDOWTHEME, 0, Integer(pwStr));
end;

class procedure ToolTipsAPI.TrackActivate(hWndControl: THandle;
  bActivate: Boolean; lpti: PToolInfo);
begin
  SendMessage(hWndControl, TTM_TRACKACTIVATE, Integer(bActivate), Integer(lpti));
end;

class procedure ToolTipsAPI.TrackPosition(hWndControl: THandle; xPos,
  yPos: Word);
begin
  SendMessage(hWndControl, TTM_TRACKPOSITION, 0, MakeLong(xPos, yPos));
end;

class procedure ToolTipsAPI.Update(hWndControl: THandle);
begin
  SendMessage(hWndControl, TTM_UPDATE, 0, 0);
end;

class procedure ToolTipsAPI.UpdateText(hWndControl: THandle;
  lpti: PToolInfo);
begin
  SendMessage(hWndControl, TTM_UPDATETIPTEXT, 0, Integer(lpti));
end;

class function ToolTipsAPI.WindowFromPoint(hWndControl: THandle;
  lppt: PPoint): Longint;
begin
  Result := SendMessage(hWndControl, TTM_WINDOWFROMPOINT, 0, Integer(lppt));
end;

{ TToolTipWindow }

const
  TTS_NOANIMATE = $10;
  TTS_NOFADE = $20;
  TTS_CLOSE = $80;
  TTS_USEVISUALSTYLE = $100;

const
  ToolTipStyleValue: array [TToolTipStyle] of Longword = (TTS_ALWAYSTIP,
    TTS_BALLOON, TTS_NOANIMATE, TTS_NOFADE, TTS_NOPREFIX, TTS_CLOSE,
    TTS_USEVISUALSTYLE);

function ToolTipStylesValue(const Styles: TToolTipStyles): Longword;
var
  Style: TToolTipStyle;
begin
  Result := 0;
  for Style := Low(TToolTipStyle) to High(TToolTipStyle) do
    if Style in Styles then
      Result := Result or ToolTipStyleValue[Style];
end;

function GetToolTipStyles(const Value: Longint): TToolTipStyles;
var
  Style: TToolTipStyle;
begin
  Result := [];
  for Style := Low(TToolTipStyle) to High(TToolTipStyle) do
    if Value and ToolTipStyleValue[Style] <> 0 then
      Include(Result, Style);
end;

procedure TToolTipWindow.AfterConstruction;
const
  nIndex = GWL_WNDPROC; {offset of value to set}
var
  dwNewLong: Longint; {new value}
begin
  inherited;

  // Subclass ToolTip control.
  fWndProcPtr := MakeObjectInstance(WndProc);
  dwNewLong := Longint(fWndProcPtr);
  fPrevWndProc := Pointer(Window_SetLong(Parent.Handle, nIndex, dwNewLong));
end;

constructor TToolTipWindow.Create(AParent: TWinControl);
const
  lpWindowName = nil; {pointer to window name}
  hMenu = 0; {handle to menu, or child-window identifier}
  lpParam = nil; {pointer to window-creation data}
  hWndInsertAfter = HWND_TOPMOST; {placement-order handle}
  uFlags = SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE; {positioning flags}
var
  dwExStyle: Longword; {extended window style}
  lpClassName: PAnsiChar; {pointer to registered class name}
  dwStyle: Longword; {window style}
  x: Integer; {horizontal position of window}
  y: Integer; {vertical position of window}
  nWidth: Integer; {window width}
  nHeight: Integer; {window height}
  hWndParent: THandle; {handle to parent or owner window}
begin
  fParent := AParent;
  (* CREATE A TOOLTIP WINDOW *)
  dwExStyle := WS_EX_TOPMOST or GetWindowExStyle;
  lpClassName := GetWindowClassName;
  // SS110312: WS_EX_TOOLWINDOW removed from window style
  dwStyle := WS_POPUP or GetWindowStyle;
  x := Integer(CW_USEDEFAULT);
  y := Integer(CW_USEDEFAULT);
  nWidth := Integer(CW_USEDEFAULT);
  nHeight := Integer(CW_USEDEFAULT);
  hWndParent := fParent.Handle;
  fHandle := Window_CreateEx(dwExStyle, lpClassName, lpWindowName, dwStyle,
    x, y, nWidth, nHeight, hWndParent, hMenu, lpParam);

  x := 0;
  y := 0;
  nWidth := 0;
  nHeight := 0;
  Window_SetPos(fHandle, hWndInsertAfter, x, y, nWidth, nHeight, uFlags);
end;

constructor TToolTipWindow.CreateStyled(AParent: TWinControl;
  AStyles: TToolTipStyles);
begin
  fStyles := AStyles;

  Create(AParent);
end;

function TToolTipWindow.GetStyles: TToolTipStyles;
const
  nIndex = GWL_STYLE; {offset of value to retrieve}
begin
  fStyles := GetToolTipStyles(Window_GetLong(Handle, nIndex));
  Result := fStyles;
end;

function TToolTipWindow.GetWindowClassName: PAnsiChar;
begin
  Result := TOOLTIPS_CLASS;
end;

function TToolTipWindow.GetWindowExStyle: Longword;
begin
  Result := 0;  
end;

function TToolTipWindow.GetWindowStyle: Longword;
begin
  Result := ToolTipStylesValue(fStyles);
end;

procedure TToolTipWindow.TTNGetDispInfo(var Message: TTTNGetDispInfo);
begin
  if Assigned(fOnGetDispInfo) then
    fOnGetDispInfo(Self, Message.lpnmtdi^);
end;

procedure TToolTipWindow.TTNLinkClick(var Message: TTTNLinkClick);
begin
  if Assigned(fOnLinkClick) then
    fOnLinkClick(Self);
end;

procedure TToolTipWindow.TTNPop(var Message: TTTNPop);
begin
  if Assigned(fOnPop) then
    fOnPop(Self, Message.idTT, Message.pnmh^);
  // SS110312: If in-place tooltip canceled, XP does not send further TTN_GETDISPINFO
  PostMessage(Handle, TTM_POP, 0, 0);
end;

procedure TToolTipWindow.TTNShow(var Message: TTTNShow);
begin
  if Assigned(fOnShow) then
    fOnShow(Self, Message.idTT, Message.pnmh^);
end;

class function TToolTipWindow.Window_CallProc(lpPrevWndFunc: TWndProc;
  hWnd: THandle; Msg: Longword; wParam, lParam: Integer): Longint;
begin
  Result := CallWindowProc(lpPrevWndFunc, hWnd, Msg, wParam, lParam);
end;

class function TToolTipWindow.Window_CreateEx(dwExStyle: Longword;
  lpClassName, lpWindowName: PAnsiChar; dwStyle: Longword; x, y, nWidth,
  nHeight: Integer; hWndParent, hMenu: THandle; lpParam: Pointer): THandle;
begin
  Result := CreateWindowExA(dwExStyle, lpClassName, lpWindowName, dwStyle,
    x, y, nWidth, nHeight, hWndParent, hMenu, HInstance, lpParam);
  if Result = 0 then
    RaiseLastWin32Error('CreateWindowEx');
end;

class function TToolTipWindow.Window_GetLong(hWnd: THandle;
  nIndex: Integer): Longint;
begin
  Result := GetWindowLong(hWnd, nIndex);
  if Result = 0 then
    RaiseLastWin32Error('GetWindowLong');
end;

class function TToolTipWindow.Window_SetLong(hWnd: THandle; nIndex,
  dwNewLong: Integer): Longint;
begin
  Result := SetWindowLong(hWnd, nIndex, dwNewLong);
  if Result = 0 then
    RaiseLastWin32Error('SetWindowLong');
end;

class function TToolTipWindow.Window_SetPos(hWnd, hWndInsertAfter: THandle;
  x, y, nWidth, nHeight: Integer; uFlags: Longword): Boolean;
begin
  Result := SetWindowPos(hWnd, hWndInsertAfter, x, y, nWidth, nHeight, uFlags);
  if not Result then
    RaiseLastWin32Error('SetWindowPos');
end;

procedure TToolTipWindow.WMDestroy(var Message: TWMDestroy);
const
  nIndex = GWL_WNDPROC; {offset of value to set}
var
  dwNewLong: Longint; {new value}
begin
  // Remove the subclass from ToolTip control.
  dwNewLong := Longint(fPrevWndProc);
  Window_SetLong(Parent.Handle, nIndex, dwNewLong);
  FreeObjectInstance(fWndProcPtr);
  // SS110312: Force fParent to point nil
  fParent := nil;
end;

function TToolTipWindow.WMNotify(var Message: TWMNotify): Boolean;
begin
  // SS110312: return True if WM_NOTIFY message has been processed
  Result := Message.NMHdr.hwndFrom = Handle;
  if Result then
    case Message.NMHdr.code of
      TTN_GETDISPINFO: TTNGetDispInfo(TTTNGetDispInfo(Message));
      TTN_LINKCLICK: TTNLinkClick(TTTNLinkClick(Message));
      TTN_POP: TTNPop(TTTNPop(Message));
      TTN_SHOW: TTNShow(TTTNShow(Message));
    end;
end;

procedure TToolTipWindow.WndProc(var Msg: TMessage);
var
  Done: Boolean;
begin
  // SS110312: Message have to be dispatched only if it has not been processed
  Done := False;
  case Msg.Msg of
    WM_NOTIFY: Done := WMNotify(TWMNotify(Msg));
    WM_DESTROY: WMDestroy(TWMDestroy(Msg));
  end;

  if not Done and (Parent <> nil) then
    with Msg do
      Result := Window_CallProc(fPrevWndProc, Parent.Handle, Msg, wParam, lParam);
end;

type
  // SS110312: TToolTipList inherits TList instead of TObjectList
  TToolTipList = class(TList)
  private
    function GetItem(Index: Integer): TToolTip;
    procedure SetItem(Index: Integer; const Value: TToolTip);
  protected
    function GetNextId: TToolTipId;

    function DispatchGetDispInfo(AId: TToolTipId;
      var Instance: THandle; var ResName: string;
      var Text: string; Data: Longint): Boolean; virtual;
    procedure DispatchLinkClick(AId: TToolTipId); virtual;
    procedure DispatchPop(AId: TToolTipId); virtual;
    procedure DispatchShow(AId: TToolTipId); virtual;
  public
    procedure Insert(Index: Integer; AObject: TToolTip); virtual;
    function Add(AObject: TToolTip): Integer;
    function Extract(Item: TToolTip): TToolTip;
    function First: TToolTip;
    function Last: TToolTip;
    function IndexOfId(AId: TToolTipId): Integer; virtual;
    function FindById(AId: TToolTipId): TToolTip;
    property Items[Index: Integer]: TToolTip read GetItem write SetItem; default;
  end;

{ TToolTipList }

function TToolTipList.Add(AObject: TToolTip): Integer;
begin
  Result := Count;
  Insert(Result, AObject);
end;

function TToolTipList.DispatchGetDispInfo(AId: TToolTipId;
  var Instance: THandle; var ResName, Text: string;
  Data: Integer): Boolean;
begin
  Result := FindById(AId).DoGetDispInfo(Instance, ResName, Text, Data);
end;

procedure TToolTipList.DispatchLinkClick(AId: TToolTipId);
begin
  FindById(AId).DoLinkClick;
end;

procedure TToolTipList.DispatchPop(AId: TToolTipId);
begin
  FindById(AId).DoPop;
end;

procedure TToolTipList.DispatchShow(AId: TToolTipId);
begin
  FindById(AId).DoShow;
end;

function TToolTipList.Extract(Item: TToolTip): TToolTip;
begin
  Result := TToolTip(inherited Extract(Item));
end;

function TToolTipList.FindById(AId: TToolTipId): TToolTip;
var
  Index: Integer;
begin
  Index := IndexOfId(AId);
  if Index < 0 then
    raise EToolTip.CreateFmt(S_EId, [AId]);
  Result := GetItem(Index);
end;

function TToolTipList.First: TToolTip;
begin
  Result := TToolTip(inherited First);
end;

function TToolTipList.GetItem(Index: Integer): TToolTip;
begin
  // SS110312: Use Get instead of inherited GetItem
  Result := TToolTip(Get(Index));
end;

function TToolTipList.GetNextId: TToolTipId;
begin
  Result := 1;
  while IndexOfId(Result) >= 0 do
    Inc(Result);
end;

function TToolTipList.IndexOfId(AId: TToolTipId): Integer;
var
  Index: Integer;
begin
  Result := -1;
  if Count = 0 then
    Exit;

  for Index := 0 to Count - 1 do
    if Items[Index].Id = AId then
    begin
      Result := Index;
      Break;
    end;
end;

procedure TToolTipList.Insert(Index: Integer; AObject: TToolTip);
begin
  inherited Insert(Index, AObject);
end;

function TToolTipList.Last: TToolTip;
begin
  Result := TToolTip(inherited Last);
end;

procedure TToolTipList.SetItem(Index: Integer; const Value: TToolTip);
begin
  // SS110312: Use Put instead of inherited SetItem
  Put(Index, Value);
end;

{ TToolTipControl }

var
  CommonControls: Cardinal = 0;

var
  AllToolTips: TToolTipList;

const
  TTI_NONE = 0;
  TTI_INFO = 1;
  TTI_WARNING = 2;
  TTI_ERROR = 3;
  TTI_INFO_LARGE = 4;
  TTI_WARNING_LARGE = 5;
  TTI_ERROR_LARGE = 6;

const
  MAX_TITLE = 99;

const
  ToolTipIconValue: array [TToolTipIcon] of Integer = (TTI_NONE, TTI_INFO,
    TTI_WARNING, TTI_ERROR, TTI_INFO_LARGE, TTI_WARNING_LARGE, TTI_ERROR_LARGE);

function GetToolTipIcon(const Value: Integer): TToolTipIcon;
var
  Icon: TToolTipIcon;
begin
  Result := ttiNone;
  for Icon := Low(TToolTipIcon) to High(TToolTipIcon) do
    if Value = ToolTipIconValue[Icon] then
    begin
      Result := Icon;
      Break;
    end;
end;

procedure TToolTipControl.Activate;
begin
  ToolTipsAPI.Activate(Handle, True);
end;

function TToolTipControl.Add(AToolTip: TToolTip): Integer;
begin
  AToolTip.Flags := AToolTip.Flags + fFlagsToInclude - fFlagsToExclude;

  AToolTip.SetOwner(Self);
  AToolTip.AddTool;

  Result := fToolTips.Add(AToolTip);
end;

procedure TToolTipControl.AddHints(AControl: TControl);
var
  Index: Integer;
begin
  if Length(AControl.Hint) > 0 then
  begin
    AControl.ShowHint := False;
    Add(TToolTip.Create(AControl));
  end;

  if AControl.ComponentCount > 0 then
    for Index := 0 to AControl.ComponentCount - 1 do
      if AControl.Components[Index] is TControl then
        AddHints(TControl(AControl.Components[Index]));
end;

function TToolTipControl.AdjustTextRect(var ARect: TRect): Boolean;
begin
  Result := ToolTipsAPI.AdjustRect(Handle, True, @ARect) <> 0;
  AfterAdjustRect(ARect);
end;

function TToolTipControl.AdjustWindowRect(var ARect: TRect): Boolean;
begin
  Result := ToolTipsAPI.AdjustRect(Handle, False, @ARect) <> 0;
  AfterAdjustRect(ARect);
end;

procedure TToolTipControl.AfterAdjustRect(var ARect: TRect);
begin
  // Nothing to do here
end;

procedure TToolTipControl.AfterConstruction;
begin
  inherited;

  fToolTips := TToolTipList.Create;
end;

procedure TToolTipControl.BeforeDestruction;
begin
  while Count > 0 do
    Remove(Items[0]);

  fToolTips.Free;
  // SS110312: Force fInfo.pszTitle to point nil
  fInfo.pszTitle := nil;

  inherited;
end;

class function TToolTipControl.CommonControls_InitEx(
  dwICC: Longword): Boolean;
var
  iccex: TInitCommonControlsEx; {struct specifying control classes to register}
begin
  Result := CommonControls and dwICC = dwICC;
  if Result then
    Exit;

  iccex.dwSize := SizeOf(TInitCommonControlsEx);
  iccex.dwICC := dwICC;
  Result := InitCommonControlsEx(iccex);
  if not Result then
    RaiseLastWin32Error('InitCommonControlsEx');
  CommonControls := CommonControls or dwICC;
end;

constructor TToolTipControl.Create(AParent: TWinControl);
begin
  inherited;

  ZeroMemory(@fInfo, SizeOf(TTTGetTitle));
  fInfo.dwSize := SizeOf(TTTGetTitle);
  // SS110312: Allocate empty string
  fInfo.cch := 0;
  fTitle := #0;
  fInfo.pszTitle := PChar(fTitle);
end;

procedure TToolTipControl.Deactivate;
begin
  ToolTipsAPI.Activate(Handle, False);
end;

function TToolTipControl.EnumTools(iTool: Longword;
  var AInfo: TToolInfo): Boolean;
begin
  Result := ToolTipsAPI.Enum(Handle, iTool, @AInfo);
end;

function TToolTipControl.GetAutoPopTime: Cardinal;
begin
  Result := ToolTipsAPI.GetDelayTime(Handle, TTDT_AUTOPOP);
end;

function TToolTipControl.GetBackColor: TColor;
begin
  Result := ToolTipsAPI.GetBkColor(Handle);
end;

function TToolTipControl.GetBottomMargin: Integer;
begin
  Result := GetMargin.Bottom;
end;

function TToolTipControl.GetCount: Integer;
begin
  Result := fToolTips.Count;
end;

function TToolTipControl.GetCurrentTool: TToolInfo;
begin
  // SS110312: Result.cbSize must be initialized
  Result.cbSize := SizeOf(ToolInfo);
  ToolTipsAPI.GetCurrent(Handle, @Result);
end;

function TToolTipControl.GetCurrentToolExists: Boolean;
begin
  Result := ToolTipsAPI.GetCurrent(Handle, nil) <> 0;
end;

function TToolTipControl.GetIcon: TToolTipIcon;
begin
  // SS110312: fInfo should not be overriden to avoid memory leaks
//  ToolTipsAPI.GetTitle(Handle, @fInfo);
  Result := GetToolTipIcon(fInfo.uTitleBitmap);
end;

function TToolTipControl.GetInitialTime: Cardinal;
begin
  Result := ToolTipsAPI.GetDelayTime(Handle, TTDT_INITIAL);
end;

function TToolTipControl.GetItem(const Index: Integer): TToolTip;
begin
  Result := TToolTipList(fToolTips).Items[Index];
end;

function TToolTipControl.GetLeftMargin: Integer;
begin
  Result := GetMargin.Left;
end;

function TToolTipControl.GetMargin: TRect;
begin
  ToolTipsAPI.GetMargin(Handle, @Result);
end;

function TToolTipControl.GetMaxTipWidth: Integer;
begin
  Result := ToolTipsAPI.GetMaxWidth(Handle);
end;

function TToolTipControl.GetReshowTime: Cardinal;
begin
  Result := ToolTipsAPI.GetDelayTime(Handle, TTDT_RESHOW);
end;

function TToolTipControl.GetRightMargin: Integer;
begin
  Result := GetMargin.Right;
end;

function TToolTipControl.GetTextColor: TColor;
begin
  Result := ToolTipsAPI.GetTextColor(Handle);
end;

function TToolTipControl.GetTool(iTool: Cardinal): TToolInfo;
begin
  ToolTipsAPI.Enum(Handle, iTool, @Result);
end;

function TToolTipControl.GetToolCount: Integer;
begin
  Result := ToolTipsAPI.GetCount(Handle);
end;

function TToolTipControl.GetTopMargin: Integer;
begin
  Result := GetMargin.Top;
end;

function TToolTipControl.HitTest(APoint: TPoint;
  var AInfo: TToolInfo): Boolean;
var
  AHitTestInfo: TTHitTestInfo;
begin
  AHitTestInfo.hwnd := Parent.Handle;
  AHitTestInfo.pt := APoint;
  AHitTestInfo.ti := AInfo;
  Result := ToolTipsAPI.HitTest(Handle, @AHitTestInfo);
  if Result then
    AInfo := AHitTestInfo.ti;
end;

procedure TToolTipControl.Pop;
begin
  ToolTipsAPI.Pop(Handle);
end;

procedure TToolTipControl.Popup;
begin
  ToolTipsAPI.Popup(Handle);
end;

procedure TToolTipControl.RelayEvent(var Msg: TMsg);
begin
  ToolTipsAPI.RelayEvent(Handle, @Msg);
end;

function TToolTipControl.Remove(AToolTip: TToolTip): Integer;
begin
  AToolTip.DelTool;
  AToolTip.SetOwner(nil);

  Result := fToolTips.Remove(AToolTip);

  // SS110312: Destroy AToolTip
  AToolTip.Free;
end;

procedure TToolTipControl.SetAutomaticDelayTime;
begin
  ToolTipsAPI.SetDelayTime(Handle, TTDT_AUTOMATIC, MakeLong(Word(-1), 0));
end;

procedure TToolTipControl.SetAutoPopTime(const Value: Cardinal);
begin
  ToolTipsAPI.SetDelayTime(Handle, TTDT_AUTOPOP, Value);
end;

procedure TToolTipControl.SetBackColor(const Value: TColor);
begin
  ToolTipsAPI.SetBkColor(Handle, Value);
end;

procedure TToolTipControl.SetBottomMargin(const Value: Integer);
var
  AMargin: TRect;
begin
  AMargin := GetMargin;
  AMargin.Bottom := Value;
  Margin := AMargin;
end;

procedure TToolTipControl.SetIcon(const Value: TToolTipIcon);
begin
  // SS110312: fInfo should not be overriden to avoid memory leaks
//  ToolTipsAPI.GetTitle(Handle, @fInfo);
  fInfo.uTitleBitmap := ToolTipIconValue[Value];
  ToolTipsAPI.SetTitle(Handle, fInfo.uTitleBitmap, fInfo.pszTitle);
end;

procedure TToolTipControl.SetInitialTime(const Value: Cardinal);
begin
  ToolTipsAPI.SetDelayTime(Handle, TTDT_INITIAL, Value);
end;

procedure TToolTipControl.SetLeftMargin(const Value: Integer);
var
  AMargin: TRect;
begin
  AMargin := GetMargin;
  AMargin.Left := Value;
  Margin := AMargin;
end;

procedure TToolTipControl.SetMargin(const Value: TRect);
begin
  ToolTipsAPI.SetMargin(Handle, @Value);
end;

procedure TToolTipControl.SetMaxTipWidth(const Value: Integer);
begin
  ToolTipsAPI.SetMaxWidth(Handle, Value);
end;

procedure TToolTipControl.SetReshowTime(const Value: Cardinal);
begin
  ToolTipsAPI.SetDelayTime(Handle, TTDT_RESHOW, Value);
end;

procedure TToolTipControl.SetRightMargin(const Value: Integer);
var
  AMargin: TRect;
begin
  AMargin := GetMargin;
  AMargin.Right := Value;
  Margin := AMargin;
end;

procedure TToolTipControl.SetTextColor(const Value: TColor);
begin
  ToolTipsAPI.SetTextColor(Handle, Value);
end;

procedure TToolTipControl.SetTitle(const Value: string);
begin
  // SS110312: Use local fTitle instead of memory management routines
  if Value = fTitle then
    Exit;

  // SS110312: Remove title limit
  if Length(Value) = 0 then
    fTitle := #0
  else
    fTitle := Value;
  fInfo.cch := Length(Value);
  fInfo.pszTitle := PChar(fTitle);
  ToolTipsAPI.SetTitle(Handle, fInfo.uTitleBitmap, fInfo.pszTitle);
end;

procedure TToolTipControl.SetTopMargin(const Value: Integer);
var
  AMargin: TRect;
begin
  AMargin := GetMargin;
  AMargin.Top := Value;
  Margin := AMargin;
end;

// SS110312: Unicode support improved
procedure TToolTipControl.SetWindowTheme(const ATheme: string);
{$IFDEF UNICODE}
begin
  ToolTipsAPI.SetWindowTheme(Handle, Pointer(ATheme));
{$ELSE}
var
  S: WideString;
begin
  S := ATheme;
  ToolTipsAPI.SetWindowTheme(Handle, PWideChar(S));
{$ENDIF}
end;

procedure TToolTipControl.TrackPosition(X, Y: Word);
begin
  ToolTipsAPI.TrackPosition(Handle, X, Y);
end;

procedure TToolTipControl.TTNGetDispInfo(var Message: TTTNGetDispInfo);
var
  AId: TToolTipId;
  Instance: THandle;
  ResName: string;
  Text: string;
  Data: Longint;
begin
  inherited;

  with Message do
  begin
    AId := lpnmtdi.hdr.idFrom;
    Instance := lpnmtdi.hinst;
    SetLength(ResName, 0);
    SetLength(Text, 0);
    Data := lpnmtdi.lParam;
    if TToolTipList(fToolTips).DispatchGetDispInfo(AId, Instance, ResName, Text,
      Data) then
      lpnmtdi.uFlags := lpnmtdi.uFlags or TTF_DI_SETITEM;
    lpnmtdi.hinst := Instance;
    if Length(Text) > 0 then
    begin
      // SS110312: Use local fTitle instead of memory management routines
      fInfo.cch := Length(Text);
      fTitle := Text;
      lpnmtdi.lpszText := PChar(fTitle);
    end
    else
      // SS110312: If in-place tooltip canceled, XP does not send further TTN_GETDISPINFO,
      //           see http://www.codeproject.com/KB/wtl/WTLTitleTipHandler.aspx?display=Print
      //           for details (German)
      PostMessage(Handle, TTM_POP, 0, 0);
  end;
end;

procedure TToolTipControl.TTNLinkClick(var Message: TTTNLinkClick);
var
  AId: TToolTipId;
begin
  inherited;

  AId := TWMNotify(Message).IDCtrl;
  TToolTipList(fToolTips).DispatchLinkClick(AId);
end;

procedure TToolTipControl.TTNPop(var Message: TTTNPop);
var
  AId: TToolTipId;
begin
  inherited;

  AId := Message.idTT;
  TToolTipList(fToolTips).DispatchPop(AId);
end;

procedure TToolTipControl.TTNShow(var Message: TTTNShow);
var
  AId: TToolTipId;
begin
  inherited;

  AId := Message.idTT;
  TToolTipList(fToolTips).DispatchShow(AId);
  // SS110312: Do not use default tooltip position
  Message.Result := 1;
end;

procedure TToolTipControl.Update;
begin
  ToolTipsAPI.Update(Handle);
end;

function TToolTipControl.WindowFromPoint(APoint: TPoint): THandle;
begin
  Result := ToolTipsAPI.WindowFromPoint(Handle, @APoint);
end;

{ TStandardToolTipControl }

constructor TStandardToolTipControl.Create(AParent: TWinControl);
const
  dwICC = ICC_WIN95_CLASSES;
begin
  if not CommonControls_InitEx(dwICC) then
    raise EToolTip.Create(S_ENotSupported);

  // SS110312: Deal with value of fStyles if CreateStyled has been executed
  fStyles := fStyles + [ttsAlwaysTip, ttsNoPrefix];
  fFlagsToInclude := [ttfSubClass];
  fFlagsToExclude := [ttfTrack];

  inherited;
end;

{ TTrackingToolTipControl }

constructor TTrackingToolTipControl.Create(AParent: TWinControl);
const
  dwICC = ICC_BAR_CLASSES;
begin
  if not CommonControls_InitEx(dwICC) then
    raise EToolTip.Create(S_ENotSupported);

  fStyles := [ttsAlwaysTip, ttsNoPrefix];
  fFlagsToInclude := [ttfTrack];
  fFlagsToExclude := [ttfSubClass];

  inherited;
end;

{ TMultilineToolTipControl }

const
  TTWM_DEFAULT = 250;

constructor TMultilineToolTipControl.Create(AParent: TWinControl);
begin
  inherited;

  SetMaxTipWidth(TTWM_DEFAULT);
end;

{ TBalloonToolTipControl }

constructor TBalloonToolTipControl.Create(AParent: TWinControl);
const
  dwICC = ICC_WIN95_CLASSES;
begin
  if not CommonControls_InitEx(dwICC) then
    raise EToolTip.Create(S_ENotSupported);

  fStyles := [ttsAlwaysTip, ttsBalloon, ttsNoPrefix];
  fFlagsToInclude := [ttfSubClass, ttfTransparent];
  fFlagsToExclude := [ttfTrack];

  inherited;
end;

{ TToolTip }

procedure MakeWords(const lValue: Longword; var wLow, wHigh: Word);
asm
  push EAX
  mov EAX, lValue
  mov [wLow], AX
  shr EAX, 16
  mov [wHigh], AX
  pop EAX
end;

const
  ToolTipFlagValue: array [TToolTipFlag] of Longword = (TTF_ABSOLUTE,
    TTF_CENTERTIP, TTF_IDISHWND, TTF_PARSELINKS, TTF_RTLREADING, TTF_SUBCLASS,
    TTF_TRACK, TTF_TRANSPARENT);

function ToolTipFlagsValue(const Flags: TToolTipFlags): Longword;
var
  Flag: TToolTipFlag;
begin
  Result := 0;
  for Flag := Low(TToolTipFlag) to High(TToolTipFlag) do
    if Flag in Flags then
      Result := Result or ToolTipFlagValue[Flag];
end;

function GetToolTipFlags(const Value: Longword): TToolTipFlags;
var
  Flag: TToolTipFlag;
begin
  Result := [];
  for Flag := Low(TToolTipFlag) to High(TToolTipFlag) do
    if Value and ToolTipFlagValue[Flag] <> 0 then
      Include(Result, Flag);
end;

function TToolTip.AddTool: Boolean;
begin
  CheckOwner('AddTool');
  Result := ToolTipsAPI.Add(Owner.Handle, @fInfo);
end;

procedure TToolTip.AfterConstruction;
begin
  inherited;

  AllToolTips.Add(Self);
end;

procedure TToolTip.BeforeDestruction;
begin
  AllToolTips.Remove(Self);
  // SS110312: Force fInfo.lpszText to point nil
  fInfo.lpszText := nil;

  inherited;
end;

procedure TToolTip.CheckOwner(const MethodName: string);
begin
  if Owner = nil then
    raise EToolTip.CreateFmt(S_ECheckOwner, [ClassName, MethodName]);
end;

constructor TToolTip.Create(AControl: TControl; const GetDispInfo: Boolean;
  AId: TToolTipId);
begin
  inherited Create;

  fOwner := nil;
  fControl := nil;
  fParent := nil;

  (* INITIALIZE MEMBERS OF THE TOOLINFO STRUCTURE *)
  ZeroMemory(@fInfo, SizeOf(TToolInfo));
  fInfo.cbSize := SizeOf(TToolInfo);
  // SS110312: fInfo.hwnd is the handle of the window that provide the text,
  //           fInfo.uId becomes the handle of the parent
  if AId = TTID_AUTO then
    fInfo.uId := AllToolTips.GetNextId
  else
    fInfo.uId := AId;
  fInfo.hInst := HInstance;
  if GetDispInfo then
  begin
    fInfo.lpszText := LPSTR_TEXTCALLBACK;
    fInfo.uFlags := fInfo.uFlags or TTF_IDISHWND or TTF_TRANSPARENT;
    fInfo.hwnd := AId;
  end;
  fInfo.lParam := Integer(Self);
  SetControl(AControl);
  // SS110312: Initialize fText
  fText := #0;
end;

procedure TToolTip.DelTool;
begin
  CheckOwner('DelTool');
  ToolTipsAPI.Del(Owner.Handle, @fInfo);
end;

function TToolTip.DoGetDispInfo(var Instance: THandle; var ResName,
  Text: string; Data: Integer): Boolean;
begin
  if Assigned(fOnGetDispInfo) then
    Result := fOnGetDispInfo(Self, Instance, ResName, Text, Data)
  else
    Result := False;
end;

procedure TToolTip.DoLinkClick;
begin
  if Assigned(fOnLinkClick) then
    fOnLinkClick(Self);
end;

procedure TToolTip.DoPop;
begin
  if Assigned(fOnPop) then
    fOnPop(Self);
end;

procedure TToolTip.DoShow;
begin
  if Assigned(fOnShow) then
    fOnShow(Self);
end;

function TToolTip.GetBubbleSize: TSize;
var
  ABubbleSize: Longint;
  wLow, wHigh: Word;
begin
  CheckOwner('GetBubbleSize');
  if fTrackActivated then
    ABubbleSize := ToolTipsAPI.GetBubbleSize(Owner.Handle, @fInfo)
  else
    ABubbleSize := 0;
  wLow := 0;
  wHigh := 0;
  if ABubbleSize <> 0 then
    MakeWords(ABubbleSize, wLow, wHigh);
  Result.cx := wLow;
  Result.cy := wHigh;
end;

function TToolTip.GetClipRect: TRect;
begin
  if Owner <> nil then
    ToolTipsAPI.GetInfo(Owner.Handle, @fInfo);
  Result := fInfo.Rect;
end;

function TToolTip.GetFlags: TToolTipFlags;
begin
  // SS110312: fInfo should not be overriden to avoid memory leaks
//  if Owner <> nil then
//    ToolTipsAPI.GetInfo(Owner.Handle, @fInfo);
  Result := GetToolTipFlags(fInfo.uFlags);
end;

function TToolTip.GetId: TToolTipId;
begin
  Result := fInfo.uId;
end;

function TToolTip.GetToolInfo: TToolInfo;
begin
  CheckOwner('GetToolInfo');
  ToolTipsAPI.GetInfo(Owner.Handle, @Result);
end;

class function TToolTip.GetWinControl(AControl: TControl): TWinControl;
begin
  if AControl is TWinControl then
    Result := TWinControl(AControl)
  else if AControl.Parent <> nil then
    Result := AControl.Parent
  else if AControl.Owner is TControl then
    Result := GetWinControl(TControl(AControl.Owner))
  else
    raise EToolTip.CreateFmt(S_ENoWindow, [AControl.Name, AControl.ClassName]);
end;

procedure TToolTip.NewToolRect(const ARect: TRect);
begin
  fInfo.Rect := ARect;
  if Owner <> nil then
    ToolTipsAPI.NewRect(Owner.Handle, @fInfo);
end;

procedure TToolTip.SetClipRect(const Value: TRect);
begin
  fInfo.Rect := Value;
  if Owner <> nil then
    ToolTipsAPI.SetInfo(Owner.Handle, @fInfo);
end;

procedure TToolTip.SetClipRect(AControl: TControl; const Value: TRect);
var
  ARect: TRect;
begin
  if (AControl = nil) or (AControl is TWinControl) or
    (AControl.Parent = nil) then
    ARect := Value
  else
  begin
    ARect.TopLeft := AControl.ClientToParent(Point(0, 0), AControl.Parent);
    ARect.Right := ARect.Left + AControl.ClientRect.Left +
      AControl.ClientWidth;
    ARect.Bottom := ARect.Top + AControl.ClientRect.Top +
      AControl.ClientHeight;
  end;
  SetClipRect(ARect);
end;

procedure TToolTip.SetControl(const Value: TControl);
var
  ARect: TRect;
begin
  if Value = fControl then
    Exit;

  fControl := Value;
  if fControl = nil then
  begin
    fParent := nil;
    fInfo.hwnd := INVALID_HANDLE_VALUE;
    ZeroMemory(@ARect, SizeOf(TRect));
  end
  else
  begin
    fParent := GetWinControl(fControl);
    // SS110312: Store parental handle depending on TTF_IDISHWND presence
    if fInfo.uFlags and TTF_IDISHWND = TTF_IDISHWND then
      fInfo.uId := fParent.Handle
    else
      fInfo.hwnd := fParent.Handle;
    if fControl is TWinControl then
      ARect := fControl.ClientRect
    else
    begin
      ARect.TopLeft := fControl.ClientToParent(Point(0, 0), fParent);
      ARect.Right := ARect.Left + fControl.ClientRect.Left +
        fControl.ClientWidth;
      ARect.Bottom := ARect.Top + fControl.ClientRect.Top +
        fControl.ClientHeight;
    end;
    if fInfo.lpszText <> LPSTR_TEXTCALLBACK then
      SetText(fControl.Hint);
  end;
  SetClipRect(ARect);
end;

procedure TToolTip.SetFlags(const Value: TToolTipFlags);
begin
  fInfo.uFlags := ToolTipFlagsValue(Value);
  if Owner <> nil then
    ToolTipsAPI.SetInfo(Owner.Handle, @fInfo);
end;

procedure TToolTip.SetInfo(const Value: TToolInfo);
begin
  fInfo := Value;
  if Owner <> nil then
    ToolTipsAPI.SetInfo(Owner.Handle, @fInfo);
end;

procedure TToolTip.SetOwner(const Value: TToolTipControl);
begin
  fOwner := Value;
  if Owner <> nil then
    Owner.Update;
  fTrackActivated := False;
end;

procedure TToolTip.SetText(const Value: string);
begin
  // SS110312: Use local fText instead of memory management routines
  if Value = fText then
    Exit;

  fText := Value;
  if Length(Value) > 0 then
  begin
    if fInfo.lpszText = LPSTR_TEXTCALLBACK then
      raise EToolTip.Create(S_ESetText);

    fInfo.lpszText := PChar(fText);
  end
  else if fInfo.lpszText <> LPSTR_TEXTCALLBACK then
    fInfo.lpszText := nil
  else
  begin
    fText := #0;
    fInfo.lpszText := PChar(fText);
  end;

  if Owner <> nil then
    ToolTipsAPI.UpdateText(Owner.Handle, @fInfo);
end;

procedure TToolTip.TrackActivate;
begin
  CheckOwner('TrackActivate');
  ToolTipsAPI.TrackActivate(Owner.Handle, True, @fInfo);
  fTrackActivated := True;
end;

procedure TToolTip.TrackDisactivate;
begin
  CheckOwner('TrackDisactivate');
  ToolTipsAPI.TrackActivate(Owner.Handle, False, @fInfo);
end;

procedure TToolTip.TrackPosition(X, Y: Word);
begin
  CheckOwner('TrackPosition');
  Owner.TrackPosition(X, Y);
end;

{ TInPlaceToolTipControl }

procedure TInPlaceToolTipControl.AfterAdjustRect(var ARect: TRect);
const
  hWndInsertAfter = HWND_TOP; {placement-order handle}
  uFlags = SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE; {positioning flags}
var
  x: Integer; {horizontal position of window}
  y: Integer; {vertical position of window}
  nWidth: Integer; {window width}
  nHeight: Integer; {window height}
begin
  inherited;

  x := ARect.Left;
  y := ARect.Top;
  nWidth := 0;
  nHeight := 0;
  Window_SetPos(Handle, hWndInsertAfter, x, y, nWidth, nHeight, uFlags);
end;

initialization
  AllToolTips := TToolTipList.Create;

finalization
  AllToolTips.Free;

end.
