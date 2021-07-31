library MouseHook;

uses
  Windows,
  Messages;

const
  MH_MESS = WM_USER + $1000;

type
  PPointer = ^TPointer;
  TPointer = record
    Receiver: HWND;
  end;

var
  MouseHooker,FieldMap: THandle;
  FPointer: PPointer;

function JournalProc(Code:Integer;wParam:WPARAM;lParam:LPARAM): LRESULT; stdcall;

begin
  Result := CallNextHookEx(MouseHooker, Code, wParam, lParam);

  if Code = HC_ACTION then
  begin
    FieldMap := OpenFileMapping(FILE_MAP_READ,False,'PointerMap');
    if FieldMap <> 0 then FPointer := MapViewOfFile(FieldMap,FILE_MAP_READ,0,0,0);

    PostMessage(FPointer^.Receiver,MH_MESS,wParam,lParam);

    UnmapViewOfFile(FPointer);
    CloseHandle(FieldMap);
  end;
end;

procedure StartHook; stdcall;
begin
  MouseHooker := SetWindowsHookEx(WH_MOUSE, @JournalProc, hInstance, 0);
 // if MouseHooker = 0 then ShowMessage('Unable to set HOOK');
end;

procedure StopHook; stdcall;
begin
  UnhookWindowsHookEx(MouseHooker);
end;

exports
  StartHook, StopHook;

begin
end.
