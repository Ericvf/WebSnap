unit TEditCenter;

interface

Uses Windows, Classes, Controls, Forms, StdCtrls;

type
  TEdit = class(StdCtrls.TEdit)
  private
    FAlignment : TAlignment;
    procedure SetAlignment(Value: TAlignment);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    property Alignment: TAlignment read FAlignment write SetAlignment;
  end;

implementation

procedure TEdit.CreateParams(var Params: TCreateParams);
const
 Alignments : array[TAlignment] of LongWord=(ES_Left,ES_Right, ES_Center);
begin
 inherited CreateParams(Params);
 Params.Style := Params.Style or Alignments[FAlignment];
end;

procedure TEdit.SetAlignment(Value: TAlignment);
begin
 if FAlignment <> Value then
 begin
   FAlignment := Value;
   RecreateWnd;
 end;
end;

end.