{ A Lazarus component for button list

  Copyright (C) 2010 Ido Kanner idokan at@at gmail dot.dot com

  Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

unit untButtonList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Buttons, Controls, Forms, LMessages;

type
  TLayoutDirection = (ldHorizontal, ldVertical);

Const
  DEFAULT_BREAK_ON          = 5;
  DEFAULT_BUTTON_COUNT      = 10;
  DEFAULT_LAYOUT_DIRECTION  = ldVertical;
  DEFAULT_SHOW_BUTTON_HINTS = true;

type
  EButtonCount = class(Exception);

  TButtonClick = procedure (Index : Word) of object;

  { TCustomButtonList }

  TCustomButtonList = class(TScrollingWinControl)
  private
    procedure SetBreakOn ( const AValue : Word ) ;
    procedure SetButtonCount ( const AValue : Word ) ;
    procedure SetLayoutDirection ( const AValue : TLayoutDirection ) ;
    procedure SetCaptions ( const AValue : TStringList ) ;
    procedure SetHints ( const AValue : TStringList ) ;
    procedure SetButtonHints ( const AValue : Boolean ) ;
  protected
    FBreakOn         : Word;
    FButtons         : array of TBitBtn;
    FButtonCount     : Word;
    FCaptions        : TStringList;
    FHints           : TStringList;
    FLayoutDirection : TLayoutDirection;
    FShowButtonHints : Boolean;
    FButtonClick     : TButtonClick;

    procedure CreateButtons(const aFrom, aTo : Word); virtual;
    procedure CreateButtons;                          virtual;

    procedure WMSize(var Message: TLMSize); message LM_SIZE;

    function CalcHeight : Integer; virtual;
    function LayoutDirectionToChildLayout(const aDirection : TLayoutDirection) : TControlChildrenLayout; virtual;

    procedure UpdateCaptions;                   virtual;
    procedure UpdateHints;                      virtual;
    procedure CaptionChanged(Sender : TObject); virtual;
    procedure HintChanged(Sender : TObject);    virtual;

    procedure ButtonClicked(Sender : TObject); virtual;
  public
    constructor Create(AOwner: TComponent);     override;
    destructor Destroy;                         override;
  published
    property BreakOn  : Word read FBreakOn     write SetBreakOn
                                                   default DEFAULT_BREAK_ON;
    property Captions : TStringList read FCaptions write SetCaptions;
    property Count    : Word read FButtonCount write SetButtonCount
                                                   default DEFAULT_BUTTON_COUNT;
    property Hints    : TStringList read FHints write SetHints;
    property LayoutDirection : TLayoutDirection read  FLayoutDirection
                                                write SetLayoutDirection
                                               default DEFAULT_LAYOUT_DIRECTION;
    property ShowHints : Boolean read FShowButtonHints write SetButtonHints
                                              default DEFAULT_SHOW_BUTTON_HINTS;

    property OnButtonClick : TButtonClick read FButtonClick write FButtonClick;
  end;

  TButtonList = class(TCustomButtonList)
  published
    property Align;
    property Anchors;
    property AutoScroll default True;
    property AutoSize;
    property BorderSpacing;
    property BiDiMode;
    property BorderStyle default bsSingle;
    property BreakOn;
    property Captions;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Constraints;
    property Count;
    property Color nodefault;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property LayoutDirection;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property ShowHints;
    property TabOrder;
    property TabStop;
    property Visible;

    property OnButtonClick;
    property OnClick;
    property OnConstrainedResize;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property OnPaint;
  end;

procedure Register;

resourcestring
  errCreationIndexOutOfRange     = 'Creation index out of range';
  errToIsBiggerThenFrom          = 'To is bigger then from';
  errCannotCreateEmptyButtonList = 'Cannot create empty button list';

implementation

{ TCustomButtonList }

constructor TCustomButtonList.Create ( AOwner : TComponent ) ;
begin
  inherited Create ( AOwner ) ;

  ControlStyle := ControlStyle - [csAcceptsControls, csSetCaption]
                               + [csOpaque];

  SetInitialBounds(
                   0, 0,
                   GetControlClassDefaultSize.X,
                   GetControlClassDefaultSize.Y
                  );

  FBreakOn                      := DEFAULT_BREAK_ON;
  FButtonCount                  := DEFAULT_BUTTON_COUNT;
  FLayoutDirection              := DEFAULT_LAYOUT_DIRECTION;

  // Setting control layout
  ChildSizing.Layout            := LayoutDirectionToChildLayout(FLayoutDirection);
  ChildSizing.ControlsPerLine   := FBreakOn;
  ChildSizing.EnlargeHorizontal := crsScaleChilds;
  AutoScroll                    := True;
  AutoSize                      := False;

  FCaptions                     := TStringList.Create;
  FCaptions.OnChange            := @CaptionChanged;
  FHints                        := TStringList.Create;
  FHints.OnChange               := @HintChanged;
  FShowButtonHints              := DEFAULT_SHOW_BUTTON_HINTS;

  SetLength(FButtons, FButtonCount);
  CreateButtons;
end;

destructor TCustomButtonList.Destroy;
var
  i : word;
begin
  FreeAndNil(FCaptions);
  FreeAndNil(FHints);

  for i := Low(FButtons) to High(FButtons) do
    begin
      if Assigned(FButtons[i]) then
        FreeAndNil(FButtons[i]);
    end;

  inherited Destroy;
end;

procedure TCustomButtonList.CreateButtons ( const aFrom, aTo : Word ) ;
var
  i         : integer;
  BtnHeight : integer;
begin
  if aFrom > High(FButtons) then
    raise EButtonCount.Create(errCreationIndexOutOfRange);
  if aTo = 0 then raise EButtonCount.Create(errCreationIndexOutOfRange);
  if aFrom > aTo then raise EButtonCount.Create(errToIsBiggerThenFrom);

  BtnHeight := CalcHeight;

  for i := aFrom to aTo do
    begin
      if not Assigned(FButtons[i]) then
        FButtons[i] := TBitBtn.Create(self);

      FButtons[i].AutoSize              := true;
      FButtons[i].Parent                := Self;
      FButtons[i].ShowHint              := FShowButtonHints;
      FButtons[i].Constraints.MinHeight := BtnHeight;
      FButtons[i].Tag                   := i;
      FButtons[i].OnClick               := @ButtonClicked;
    end;
end;

procedure TCustomButtonList.CreateButtons;
begin
  CreateButtons(Low(FButtons), High(FButtons));
end;

procedure TCustomButtonList.WMSize ( var Message : TLMSize ) ;
var
  i         : integer;
  BtnHeight : integer;
begin
  Message.Result := 1;

  // Recalculate the height of the buttons
  // depands on the new height
  BtnHeight      := CalcHeight;

  for i := Low(FButtons) to High(FButtons) do
    begin
      FButtons[i].Constraints.MinHeight := BtnHeight;
    end;

  if Assigned(OnResize) then
    OnResize(Self);
end;

function TCustomButtonList.CalcHeight : Integer;
begin
  Result := (Self.ClientHeight div FBreakOn);
  // We can not go bellow 26 pixels on hight
  if Result < 30 then
    Result := 30;
end;

function TCustomButtonList.LayoutDirectionToChildLayout (
  const aDirection : TLayoutDirection ) : TControlChildrenLayout;
const
  Layout : array[TLayoutDirection] of TControlChildrenLayout =
   (cclLeftToRightThenTopToBottom, cclTopToBottomThenLeftToRight);
begin
  Result := Layout[aDirection];
end;

procedure TCustomButtonList.SetBreakOn ( const AValue : Word ) ;
begin
  if AValue <> FBreakOn then
    begin
      FBreakOn                    := AValue;
      ChildSizing.ControlsPerLine := FBreakOn;
    end;
end;

procedure TCustomButtonList.SetButtonCount ( const AValue : Word ) ;
var
  i : integer;
begin
  if AValue = 0 then
    raise EButtonCount.Create(errCannotCreateEmptyButtonList);

  if AValue <> FButtonCount then
    begin
      if FButtonCount > AValue then
        begin
          for i := AValue to FButtonCount -1 do
            FreeAndNil(FButtons[i]);

          SetLength(FButtons, AValue); // shrink array
        end
      else begin
             SetLength(FButtons, AValue); // resize array
             CreateButtons(FButtonCount, AValue-1);
           end;

      FButtonCount := AValue;
    end;
end;

procedure TCustomButtonList.SetLayoutDirection (
  const AValue : TLayoutDirection ) ;
begin
   if AValue <> FLayoutDirection then
     begin
       FLayoutDirection   := AValue;
       ChildSizing.Layout := LayoutDirectionToChildLayout(FLayoutDirection);
     end;
end;

procedure TCustomButtonList.CaptionChanged ( Sender : TObject ) ;
begin
  UpdateCaptions;
end;

procedure TCustomButtonList.HintChanged ( Sender : TObject ) ;
begin
  UpdateHints;
end;

procedure TCustomButtonList.UpdateCaptions;
var
  i            : word;
  max_captions : word;
begin
  if FCaptions.Count <= 0 then exit;

  if FCaptions.Count > Length(FButtons) then
    max_captions := Length(FButtons)
  else
    max_captions := FCaptions.Count;

  for i := 0 to max_captions -1 do
    begin
      FButtons[i].Caption := FCaptions.Strings[i];
    end;
end;

procedure TCustomButtonList.UpdateHints;
var
  i         : word;
  max_hints : word;
begin
  if FHints.Count <= 0 then exit;

  if FHints.Count > Length(FButtons) then
    max_hints := Length(FButtons)
  else
    max_hints := FHints.Count;

  for i := 0 to max_hints -1 do
    begin
      FButtons[i].Hint := FHints.Strings[i];
    end;
end;

procedure TCustomButtonList.SetCaptions ( const AValue : TStringList ) ;
begin
  if AValue.Equals(FCaptions) then exit;

  FCaptions.Clear;
  FCaptions.Assign(AValue);
  UpdateCaptions;
end;

procedure TCustomButtonList.SetHints ( const AValue : TStringList ) ;
begin
  if AValue.Equals(FHints) then exit;

  FHints.Clear;
  FHints.Assign(AValue);
  UpdateHints;
end;

procedure TCustomButtonList.SetButtonHints ( const AValue : Boolean ) ;
var
  i : word;
begin
  if FShowButtonHints = AValue then exit;
  FShowButtonHints := AValue;

  for i := Low(FButtons) to High(FButtons) do
    begin
      FButtons[i].ShowHint := FShowButtonHints;
    end;
end;

procedure TCustomButtonList.ButtonClicked ( Sender : TObject ) ;
begin
  if Assigned(FButtonClick) then
    FButtonClick(TBitBtn(Sender).Tag);
end;

procedure Register;
begin
  RegisterComponents('LINESIP Buttons', [TButtonList]);
end;

end.

