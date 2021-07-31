unit TTrayIcon;

interface

uses
  Messages, Forms, SysUtils, Classes, Graphics, ShellAPI;

type
  TWndMethod = procedure(var Message: TMessage) of object;

var
  IconData: TNOTIFYICONDATA;

const
  WM_ICONACTION = WM_USER + $1001;

procedure CreateIcon(Msg: TWndMethod; Icon: TIcon; Tip: String);
Procedure KillIcon;

implementation

procedure CreateIcon(Msg: TWndMethod; Icon: TIcon; Tip: String);
begin
  with IconData do
  begin
     uCallbackMessage := WM_ICONACTION;
     cbSize     := sizeof(TNOTIFYICONDATA);
     wnd        := AllocateHWnd( Msg );
     uID        := 0;
     uFlags     := NIF_MESSAGE + NIF_ICON + NIF_TIP;
     hIcon      := Icon.Handle;
     StrPCopy(szTip, Tip);
  end;
  Shell_NotifyIcon(NIM_ADD, @IconData);
end;

procedure KillIcon;
begin
   Shell_NotifyIcon(NIM_DELETE, @IconData);
end;

end.