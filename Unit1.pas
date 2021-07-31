unit Unit1;

interface

uses
   Windows,
   Messages,
   SysUtils,
   Classes,
   Graphics,
   Controls,
   Forms,
   StdCtrls,
   ExtCtrls,
   TEditCenter,
   TTrayIcon,
   Menus,
   Dialogs;

const
  NameOfDLL     = 'MouseHook.dll';
  MHM_MESS      = WM_USER + $1000;
  WM_ICONACTION = WM_USER + $1001;
  xOffset = 10;
  yOffset = 10;
  xPixels = 20;
  yPixels = 20;
  pixelH  = 7;

type
  TMouseHook = procedure; stdcall;
  PPointer = ^TPointer;
  TPointer = record
    Receiver: HWND;
  end;

  TForm1 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    TrayPopup: TPopupMenu;
    Exit1: TMenuItem;
    N1: TMenuItem;
    Restore1: TMenuItem;

    procedure WMHotKey(var Msg : TWMHotKey); message WM_HOTKEY;
    procedure HookMessage(var message: TMessage); message MHM_MESS;
    procedure TrayProc(var msg : TMessage);
    procedure TrayLeftClick;

    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Draw;
    procedure Edit4DblClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Exit1Click(Sender: TObject);
    procedure Restore1Click(Sender: TObject);
  private
    HandleDLL,FieldMap: THandle;
    ManualLock: boolean;
    Pointer: PPointer;
    tH,tW: integer;
  end;

var
  StartHook,StopHook: TMouseHook;
  Form1: TForm1;

implementation
{$R *.DFM}

(* -------------------------------------------------------------------------- *)
(*                           Global functions/procedures                      *)
(* -------------------------------------------------------------------------- *)
function ColorToHex(const Color: TColor): string;
begin
  Result := IntToHex(GetRValue(Color), 2)+
            IntToHex(GetGValue(Color), 2)+
            IntToHex(GetBValue(Color), 2);
end;

procedure TForm1.Draw;
var
  TMPmap, Magnify, ColorBox: TBitmap;
  x1, x2, y1, y2, cW: integer;
  DesktopCanvas: TCanvas;
  tMouse,fMouse: TPoint;
  Rect1, Rect2: TRect;
  Color: Tcolor;
begin
  GetCursorPos( tMouse );
  fMouse := ScreenToClient( tMouse );

  DesktopCanvas  := TCanvas.Create;
  DesktopCanvas.Handle  := GetWindowDC(GetDesktopWindow);
  Magnify  := TBitmap.Create;
  TMPmap   := TBitmap.Create;
  ColorBox := TBitmap.Create;

  TMPmap.Width  := xPixels;
  TMPmap.Height := yPixels;

  x1 := tMouse.X - (xPixels div 2);
  x2 := tMouse.X + (xPixels div 2);
  y1 := tMouse.Y - (yPixels div 2);
  y2 := tMouse.Y + (yPixels div 2);

  Rect1 := Rect(0,0,xPixels,yPixels);
  Rect2 := Rect(x1,y1,x2,y2);

  TMPmap.Canvas.CopyRect( Rect1, DesktopCanvas, Rect2 );

  x1 := xPixels * pixelH - 1;
  y1 := yPixels * pixelH - 1;
  with Magnify do
  begin
    Width  := x1;
    Height := y1;
    Canvas.StretchDraw( rect(0, 0, x1, y1), TMPmap );
  end;

  x1 := (tW-2) div 2 + (pixelH div 2);
  y1 := (tH-2) div 2 + (pixelH div 2);
  cW := pixelH * 2;

  with Magnify.Canvas do
  begin
    Pen.Mode := pmNot;
    MoveTo(x1 - cW ,y1);
    LineTo(x1 + cW ,y1);
    MoveTo(x1 ,y1 - cW);
    LineTo(x1 ,y1 + cW);
    Pen.Mode := pmCopy;
  end;

  Color := getPixel( DesktopCanvas.Handle, tMouse.X, tMouse.Y );
  with ColorBox do
  begin
    Width       := xPixels*pixelH + 1;
    Height      := 18;
    Canvas.Brush.Color := Color;
    Rectangle(Canvas.Handle, 0, 0, Width, Height );
  end;
  Edit1.Text := IntToStr( GetRValue( Color ));
  Edit2.Text := IntToStr( GetGValue( Color ));
  Edit3.Text := IntToStr( GetBValue( Color ));
  Edit4.Text := '#' + ColorToHex(Color);

  Canvas.Draw( xOffset, yOffset, Magnify );
  Canvas.Draw( xOffset-1, (2*yOffset)+(yPixels*pixelH), ColorBox);

  Magnify.Free;
  TMPmap.Free;
  ColorBox.Free;
  DesktopCanvas.Free;
end;
(* -------------------------------------------------------------------------- *)
(*                         LocalForm functions/procedures                     *)
(* -------------------------------------------------------------------------- *)
procedure TForm1.TrayLeftClick;
begin
  if Visible = FALSE then
  begin
    StartHook;
    Application.Restore;
    Visible := TRUE;
  end else begin
    Visible := False;
    if Assigned(StopHook) then StopHook;
  end;
end;

procedure TForm1.TrayProc(var msg : TMessage);
var Mouse: Tpoint;
begin
  with msg do
    if (msg = WM_ICONACTION) then begin
      GetCursorPos(Mouse);
      case lParam of
        WM_LBUTTONUP     : TrayLeftClick;
        WM_RBUTTONUP     : TrayPopup.Popup(Mouse.X,Mouse.Y);
      end;
    end;
end;

procedure TForm1.HookMessage(var message: TMessage);
begin
  draw;
end;

procedure TForm1.WMHotKey(var Msg : TWMHotKey);
begin
  case Msg.HotKey of
    1: case manualLock of
         TRUE : begin manualLock :=FALSE; StartHook end;
         FALSE: begin manualLock := TRUE; StopHook end;
       end;
  end;

  MessageBeep(0);
end;
(* -------------------------------------------------------------------------- *)
procedure TForm1.FormCreate(Sender: TObject);
var i:integer;
begin
  // DLL
  HandleDLL  := LoadLibrary( NameOfDLL );
  if HandleDLL = 0 then
  begin
    raise Exception.Create('DLL '''+NameOfDLL+''' missing');
    Application.Terminate;
  end;    

  @StartHook := GetProcAddress(HandleDLL, 'StartHook');
  @StopHook  := GetProcAddress(HandleDLL, 'StopHook');

  if not assigned(StartHook) or not assigned(StopHook) then
  begin
    raise Exception.Create('Cannot find the required DLL functions');
    Application.Terminate;
  end;
  // MouseHook
  FieldMap := CreateFileMapping($FFFFFFFF,nil,PAGE_READWRITE,0,SizeOf(Pointer),'PointerMap');

  Pointer  := MapViewOfFile(FieldMap,FILE_MAP_WRITE,0,0,0);
  Pointer^.Receiver := Handle;

  StartHook;
  // TrayIcon
  CreateIcon(TrayProc, Application.Icon, 'WebSnap v0.2');
  
  //
  RegisterHotKey(Handle,1,MOD_ALT,76); {ALT + (76 = 'L')}

  tW := xPixels * pixelH;
  tH := yPixels * pixelH;

  Form1.Width := (xOffset*2) + tW + 5;
  Form1.Caption := 'WebSnap';
  Form1.Icon := Application.Icon;
  for i:=1 to 4 do
    with TEdit(FindComponent('Edit'+IntToStr(i))) do begin
      Alignment := taCenter;
      ReadOnly  := TRUE;
    end;

end;

procedure TForm1.FormPaint(Sender: TObject);
var
  X1,Y1,X2,Y2: integer;
  Border: TBitmap;
begin
  Border := TBitmap.Create;

  X1     := xOffset -1;
  Y1     := yOffset -1;
  X2     := tW + 1;
  Y2     := tH + 1;

  with Border do
  begin
    Width              := X2;
    Height             := Y2;
    Canvas.Pen.Color   := clBlack;
    Canvas.Brush.Color := clBlack;
    Canvas.Rectangle(0,0,X2,Y2);
  end;

  Canvas.Draw(X1,Y1,Border);
  Border.Free;
  Draw;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FALSE;
  Visible  := FALSE;
  if assigned(StopHook) then StopHook;
end;

procedure TForm1.Edit4DblClick(Sender: TObject);
begin
  Edit4.CopyToClipboard;
  Beep;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
 if assigned(StopHook) then StopHook;
 UnregisterHotKey(Handle,1);
 KillIcon;
 Application.Terminate;
end;

procedure TForm1.Restore1Click(Sender: TObject);
begin
  TrayLeftClick;
end;

end.

