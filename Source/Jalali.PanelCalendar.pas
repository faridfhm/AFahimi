unit Jalali.PanelCalendar;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.DateUtils,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Forms,
  Jalali.Calendar,
  Jalali.Consts;

type
  TJalaliDateChangeEvent = procedure(Sender: TObject; const ADate: TJalaliDate) of object;
  TCalendarViewMode = (vmDays, vmMonths, vmYears);

  TJalaliPanelCalendar = class(TCustomControl)
  private
    FProducer: string;
    FSelectedDate: TJalaliDate;
    FDisplayYear: Integer;
    FDisplayMonth: Integer;
    FHoverIndex: Integer;
    FViewMode: TCalendarViewMode;
    FOnSelectDate: TJalaliDateChangeEvent;

    FHeaderHeight: Integer;
    FWeekHeaderHeight: Integer;
    FFooterHeight: Integer;
    FCellHeight: Integer;

    FBorderColor: TColor;
    FHeaderBack: TColor;
    FWeekBack: TColor;
    FSelectBack: TColor;
    FSelectPen: TColor;
    FInactiveColor: TColor;
    FFridayColor: TColor;

    function GetMaxHeaderCellWidth: Integer;
    function HeaderRect: TRect;
    function MonthTextRect: TRect;
    function YearTextRect: TRect;
    function WeekHeaderRect: TRect;
    function GridRect: TRect;
    function FooterRect: TRect;

    function PrevButtonRect: TRect;
    function NextButtonRect: TRect;

    function VisualColOfLogical(ALogicalCol: Integer): Integer;
    function LogicalColOfVisual(AVisualCol: Integer): Integer;

    function GetCellRect(ALogicalCol, ARow, CellW: Integer): TRect;
    function LogicalColAt(X, CellW: Integer): Integer;

    function DaysInDisplayMonth: Integer;
    function FirstDayOffset_Sat0: Integer;

    function PrevMonthYear(out AYear, AMonth: Integer): Boolean;
    function NextMonthYear(out AYear, AMonth: Integer): Boolean;
    function DaysInPrevMonth: Integer;

    function DayIndexAtPos(X, Y, CellW: Integer; out AIndex: Integer): Boolean;
    function MonthIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
    function YearIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
    function StartYearOfDecade(AYear: Integer): Integer;

    procedure EnsureDisplayInitialized;
    procedure SetDisplay(AYear, AMonth: Integer);
    procedure StepMonth(Delta: Integer);

    procedure SelectByGridIndex(AIndex: Integer);
    procedure MoveSelectionByDays(Delta: Integer);

    procedure DrawArrowLeft(const R: TRect);
    procedure DrawArrowRight(const R: TRect);
    procedure DrawCenteredText(const S: string; const R: TRect; AColor: TColor; ABold: Boolean = False);
    procedure SetSelectedDate(const Value: TJalaliDate);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure AdjustDimensions;
    property SelectedDate: TJalaliDate read FSelectedDate write SetSelectedDate;
  published
    property Align;
    property Anchors;
    property BiDiMode;
    property Color default clWhite;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property BorderColor: TColor read FBorderColor write FBorderColor default $00CFCFCF;
    property HeaderBack: TColor read FHeaderBack write FHeaderBack default $00F3F3F3;
    property WeekBack: TColor read FWeekBack write FWeekBack default $00FBFBFB;
    property SelectBack: TColor read FSelectBack write FSelectBack default $00EEDDCB;
    property SelectPen: TColor read FSelectPen write FSelectPen default $00D0B090;

    property OnSelectDate: TJalaliDateChangeEvent read FOnSelectDate write FOnSelectDate;
  end;

//procedure Register;

implementation

const
  CGridRows = 6;
  CGridCols = 7;
  CTotalCells = CGridRows * CGridCols;
  C_PRODUCER_TEXT = 'AFSoft2010@gmail.com';

function JalaliToLongText(const ADate: TJalaliDate): string;
begin
  Result := Format('%d %s %d', [ADate.Day, JalaliMonthNames[ADate.Month], ADate.Year]);
end;

{ TJalaliPanelCalendar }

constructor TJalaliPanelCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProducer := C_PRODUCER_TEXT;
  DoubleBuffered := True;
  TabStop := True;
  BiDiMode := bdRightToLeft;
  ParentBiDiMode := False;

  FHeaderHeight := 34;
  FWeekHeaderHeight := 26;
  FFooterHeight := 34;
  FCellHeight := 28;

  FBorderColor := $00CFCFCF;
  FHeaderBack := $00F3F3F3;
  FWeekBack := $00FBFBFB;
  FSelectBack := $00EEDDCB;
  FSelectPen := $00D0B090;
  FInactiveColor := clGrayText;
  FFridayColor := clRed;

  Color := clWhite;
  FHoverIndex := -1;
  FViewMode := vmDays;

  FSelectedDate := TJalaliCalendar.Today;
  FDisplayYear := FSelectedDate.Year;
  FDisplayMonth := FSelectedDate.Month;

  Width := 210;
  Height := FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight) + FFooterHeight;
end;

procedure TJalaliPanelCalendar.AdjustDimensions;
var
  CW, RequiredWidth, RequiredHeight: Integer;
begin
  EnsureDisplayInitialized;
  CW := GetMaxHeaderCellWidth;
  RequiredWidth := CW * CGridCols;
  RequiredHeight := FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight) + FFooterHeight;

  SetBounds(Left, Top, RequiredWidth, RequiredHeight);
end;

procedure TJalaliPanelCalendar.EnsureDisplayInitialized;
begin
  if (FDisplayYear = 0) or (FDisplayMonth = 0) then
  begin
    FSelectedDate := TJalaliCalendar.Today;
    FDisplayYear := FSelectedDate.Year;
    FDisplayMonth := FSelectedDate.Month;
  end;
end;

function TJalaliPanelCalendar.GetMaxHeaderCellWidth: Integer;
var
  I, MaxW, W: Integer;
begin
  Canvas.Font.Assign(Self.Font);
  MaxW := 0;
  for I := 0 to 6 do
  begin
    W := Canvas.TextWidth(JalaliShortDayNames[I]);
    if W > MaxW then MaxW := W;
  end;
  Result := MaxW + 18;
end;

function TJalaliPanelCalendar.HeaderRect: TRect;
begin
  Result := Rect(0, 0, Width, FHeaderHeight);
end;

function TJalaliPanelCalendar.MonthTextRect: TRect;
var Middle: Integer;
begin
  Middle := Width div 2;
  Result := Rect(Middle, 0, Middle + 65, FHeaderHeight);
end;

function TJalaliPanelCalendar.YearTextRect: TRect;
var Middle: Integer;
begin
  Middle := Width div 2;
  Result := Rect(Middle - 65, 0, Middle, FHeaderHeight);
end;

function TJalaliPanelCalendar.WeekHeaderRect: TRect;
begin
  if FViewMode = vmDays then
    Result := Rect(0, FHeaderHeight, Width, FHeaderHeight + FWeekHeaderHeight)
  else
    Result := Rect(0, FHeaderHeight, 0, FHeaderHeight);
end;

function TJalaliPanelCalendar.GridRect: TRect;
begin
  if FViewMode = vmDays then
    Result := Rect(0, FHeaderHeight + FWeekHeaderHeight, Width, FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight))
  else
    Result := Rect(0, FHeaderHeight, Width, FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight));
end;

function TJalaliPanelCalendar.FooterRect: TRect;
begin
  Result := Rect(0, FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight), Width, Height);
end;

function TJalaliPanelCalendar.PrevButtonRect: TRect;
begin
  Result := Rect(Width - 30, 6, Width - 6, FHeaderHeight - 6);
end;

function TJalaliPanelCalendar.NextButtonRect: TRect;
begin
  Result := Rect(6, 6, 30, FHeaderHeight - 6);
end;

function TJalaliPanelCalendar.VisualColOfLogical(ALogicalCol: Integer): Integer;
begin
  Result := (CGridCols - 1) - ALogicalCol;
end;

function TJalaliPanelCalendar.LogicalColOfVisual(AVisualCol: Integer): Integer;
begin
  Result := (CGridCols - 1) - AVisualCol;
end;

function TJalaliPanelCalendar.GetCellRect(ALogicalCol, ARow, CellW: Integer): TRect;
var
  VCol, L, T: Integer;
begin
  VCol := VisualColOfLogical(ALogicalCol);
  L := VCol * CellW;
  T := FHeaderHeight + FWeekHeaderHeight + (ARow * FCellHeight);
  Result := Rect(L, T, L + CellW, T + FCellHeight);
end;

function TJalaliPanelCalendar.LogicalColAt(X, CellW: Integer): Integer;
begin
  if CellW <= 0 then Exit(-1);
  Result := LogicalColOfVisual(X div CellW);
end;

function TJalaliPanelCalendar.DaysInDisplayMonth: Integer;
begin
  Result := TJalaliCalendar.DaysInMonth(FDisplayYear, FDisplayMonth);
end;

function TJalaliPanelCalendar.StartYearOfDecade(AYear: Integer): Integer;
begin
  Result := (AYear div 10) * 10;
end;

procedure TJalaliPanelCalendar.Paint;
var
  R, CR: TRect;
  CW, LogicalCol, Row, Col, Offset, Index, CurDay, PrevDays: Integer;
  S: string;
  CellYear, CellMonth, CellDay: Integer;
  InMonth, IsFriday: Boolean;
  TextColor: TColor;
  W, H, MRow, MCol, StartY, CurY: Integer;
  TempRect: TRect;
  TempStr: string;
begin
  inherited;
  EnsureDisplayInitialized;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  // کشیدن کادر دور پنل
  Canvas.Pen.Color := FBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(0, 0, Width, Height);

  Canvas.Brush.Color := FHeaderBack;
  Canvas.FillRect(HeaderRect);

  CR := PrevButtonRect; DrawArrowRight(CR);
  CR := NextButtonRect; DrawArrowLeft(CR);

  case FViewMode of
    vmDays:
    begin
      DrawCenteredText(JalaliMonthNames[FDisplayMonth], MonthTextRect, Font.Color, True);
      DrawCenteredText(IntToStr(FDisplayYear), YearTextRect, Font.Color, True);
    end;
    vmMonths:
    begin
      R := HeaderRect;
      DrawCenteredText(IntToStr(FDisplayYear), R, Font.Color, True);
    end;
    vmYears:
    begin
      R := HeaderRect;
      StartY := StartYearOfDecade(FDisplayYear);
      DrawCenteredText(Format('%d - %d', [StartY, StartY + 9]), R, Font.Color, True);
    end;
  end;

  if FViewMode = vmDays then
  begin
    CW := Width div CGridCols;
    Offset := FirstDayOffset_Sat0;
    PrevDays := DaysInPrevMonth;

    Canvas.Brush.Color := FWeekBack;
    Canvas.FillRect(WeekHeaderRect);

    for LogicalCol := 0 to 6 do
    begin
      R := Rect(VisualColOfLogical(LogicalCol) * CW, FHeaderHeight, (VisualColOfLogical(LogicalCol) + 1) * CW, FHeaderHeight + FWeekHeaderHeight);
      if LogicalCol = 6 then TextColor := FFridayColor else TextColor := Font.Color;
      DrawCenteredText(JalaliShortDayNames[LogicalCol], R, TextColor, False);
    end;

    for Row := 0 to CGridRows - 1 do
      for Col := 0 to CGridCols - 1 do
      begin
        Index := Row * CGridCols + Col;
        LogicalCol := Col;
        CurDay := (Index - Offset) + 1;

        if CurDay < 1 then
        begin
          InMonth := False;
          CellYear := FDisplayYear; CellMonth := FDisplayMonth; CellDay := PrevDays + CurDay;
          PrevMonthYear(CellYear, CellMonth);
        end
        else if CurDay > DaysInDisplayMonth then
        begin
          InMonth := False;
          CellYear := FDisplayYear; CellMonth := FDisplayMonth; CellDay := CurDay - DaysInDisplayMonth;
          NextMonthYear(CellYear, CellMonth);
        end
        else
        begin
          InMonth := True;
          CellYear := FDisplayYear; CellMonth := FDisplayMonth; CellDay := CurDay;
        end;

        R := GetCellRect(LogicalCol, Row, CW);

        if (FSelectedDate.Year = CellYear) and (FSelectedDate.Month = CellMonth) and (FSelectedDate.Day = CellDay) then
        begin
          Canvas.Brush.Style := bsSolid;
          Canvas.Brush.Color := FSelectBack;
          Canvas.Pen.Color := FSelectPen;
          Canvas.RoundRect(R.Left + 2, R.Top + 2, R.Right - 2, R.Bottom - 2, 4, 4);
        end
        else if Index = FHoverIndex then
        begin
          Canvas.Brush.Style := bsSolid;
          Canvas.Brush.Color := $00F2F2F2;
          Canvas.Pen.Color := $00E0E0E0;
          Canvas.RoundRect(R.Left + 2, R.Top + 2, R.Right - 2, R.Bottom - 2, 4, 4);
        end;

        IsFriday := (LogicalCol = 6);
        if not InMonth then TextColor := FInactiveColor
        else if IsFriday then TextColor := FFridayColor
        else TextColor := Font.Color;

        DrawCenteredText(IntToStr(CellDay), R, TextColor, False);
      end;
  end
  else if FViewMode = vmMonths then
  begin
    R := GridRect;
    W := R.Width div 3;
    H := R.Height div 4;
    for Index := 0 to 11 do
    begin
      MRow := Index div 3;
      MCol := 2 - (Index mod 3);
      CR := Rect(R.Left + MCol * W, R.Top + MRow * H, R.Left + (MCol + 1) * W, R.Top + (MRow + 1) * H);
      InflateRect(CR, -4, -4);

      Canvas.Brush.Style := bsSolid;
      if FDisplayMonth = (Index + 1) then
      begin
        Canvas.Brush.Color := FSelectBack;
        Canvas.Pen.Color := FSelectPen;
        Canvas.RoundRect(CR.Left, CR.Top, CR.Right, CR.Bottom, 4, 4);
      end
      else if Index = FHoverIndex then
      begin
        Canvas.Brush.Color := $00F2F2F2;
        Canvas.Pen.Color := $00E0E0E0;
        Canvas.RoundRect(CR.Left, CR.Top, CR.Right, CR.Bottom, 4, 4);
      end
      else
      begin
        Canvas.Brush.Color := clWhite;
        Canvas.FillRect(CR);
      end;

      DrawCenteredText(JalaliMonthNames[Index + 1], CR, Font.Color, False);
    end;
  end;

  Canvas.Brush.Style := bsSolid;
  if FHoverIndex = -2 then Canvas.Brush.Color := $00EAEAEA else Canvas.Brush.Color := FHeaderBack;
  Canvas.FillRect(FooterRect);

  Canvas.Pen.Color := FBorderColor;
  Canvas.MoveTo(0, FooterRect.Top);
  Canvas.LineTo(Width, FooterRect.Top);

  S := 'امروز: ' + JalaliToLongText(TJalaliCalendar.Today);
  R := FooterRect;
  InflateRect(R, -10, 0);

  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Color := Font.Color;
  Canvas.Brush.Style := bsClear;

  TempRect := R;
  TempStr := S;
  Canvas.TextRect(TempRect, TempStr, [tfRight, tfVerticalCenter, tfSingleLine, tfRtlReading]);
end;

function TJalaliPanelCalendar.PrevMonthYear(out AYear, AMonth: Integer): Boolean;
begin
  AYear := FDisplayYear; AMonth := FDisplayMonth - 1;
  if AMonth < 1 then begin AMonth := 12; Dec(AYear); end;
  Result := True;
end;

function TJalaliPanelCalendar.NextMonthYear(out AYear, AMonth: Integer): Boolean;
begin
  AYear := FDisplayYear; AMonth := FDisplayMonth + 1;
  if AMonth > 12 then begin AMonth := 1; Inc(AYear); end;
  Result := True;
end;

function TJalaliPanelCalendar.DaysInPrevMonth: Integer;
var Y, M: Integer;
begin
  PrevMonthYear(Y, M); Result := TJalaliCalendar.DaysInMonth(Y, M);
end;

procedure TJalaliPanelCalendar.DrawArrowLeft(const R: TRect);
var
  Points: array[0..2] of TPoint;
  CX, CY: Integer;
begin
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Points[0] := Point(CX - 3, CY);
  Points[1] := Point(CX + 2, CY - 5);
  Points[2] := Point(CX + 2, CY + 5);
  Canvas.Brush.Color := $00444444;
  Canvas.Pen.Color := $00444444;
  Canvas.Polygon(Points);
end;

procedure TJalaliPanelCalendar.DrawArrowRight(const R: TRect);
var
  Points: array[0..2] of TPoint;
  CX, CY: Integer;
begin
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  Points[0] := Point(CX + 3, CY);
  Points[1] := Point(CX - 2, CY - 5);
  Points[2] := Point(CX - 2, CY + 5);
  Canvas.Brush.Color := $00444444;
  Canvas.Pen.Color := $00444444;
  Canvas.Polygon(Points);
end;

procedure TJalaliPanelCalendar.DrawCenteredText(const S: string; const R: TRect; AColor: TColor; ABold: Boolean);
var
  FormatFlags: TTextFormat;
  TempRect: TRect;
  TempStr: string;
begin
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Color := AColor;
  if ABold then
    Canvas.Font.Style := Canvas.Font.Style + [fsBold]
  else
    Canvas.Font.Style := Canvas.Font.Style - [fsBold];

  Canvas.Brush.Style := bsClear;
  FormatFlags := [tfCenter, tfVerticalCenter, tfSingleLine, tfRtlReading];

  TempRect := R;
  TempStr := S;
  Canvas.TextRect(TempRect, TempStr, FormatFlags);
end;

function TJalaliPanelCalendar.FirstDayOffset_Sat0: Integer;
begin
  Result := DayOfWeek(TJalaliCalendar.JalaliToDateTime(FDisplayYear, FDisplayMonth, 1)) mod 7;
end;

procedure TJalaliPanelCalendar.Resize;
begin
  inherited; Invalidate;
end;

procedure TJalaliPanelCalendar.SetDisplay(AYear, AMonth: Integer);
begin
  FDisplayYear := AYear; FDisplayMonth := AMonth; Invalidate;
end;

procedure TJalaliPanelCalendar.StepMonth(Delta: Integer);
var Y, M: Integer;
begin
  case FViewMode of
    vmDays:
    begin
      Y := FDisplayYear; M := FDisplayMonth + Delta;
      while M > 12 do begin M := M - 12; Inc(Y); end;
      while M < 1 do begin M := M + 12; Dec(Y); end;
      SetDisplay(Y, M);
    end;
    vmMonths:
    begin
      SetDisplay(FDisplayYear + Delta, FDisplayMonth);
    end;
    vmYears:
    begin
      SetDisplay(FDisplayYear + (Delta * 10), FDisplayMonth);
    end;
  end;
end;

function TJalaliPanelCalendar.DayIndexAtPos(X, Y, CellW: Integer; out AIndex: Integer): Boolean;
var GR: TRect; Row, LCol: Integer;
begin
  Result := False; GR := GridRect;
  if not PtInRect(GR, Point(X, Y)) then Exit;
  Row := (Y - GR.Top) div FCellHeight;
  if (Row < 0) or (Row >= CGridRows) then Exit;
  LCol := LogicalColAt(X, CellW);
  if (LCol < 0) or (LCol >= CGridCols) then Exit;
  AIndex := Row * CGridCols + LCol;
  Result := (AIndex >= 0) and (AIndex < CTotalCells);
end;

function TJalaliPanelCalendar.MonthIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
var GR: TRect; Row, Col: Integer;
begin
  Result := False; GR := GridRect;
  if not PtInRect(GR, Point(X, Y)) then Exit;
  Row := (Y - GR.Top) div (GR.Height div 4);
  Col := 2 - (X div (GR.Width div 3));
  if (Row >= 0) and (Row < 4) and (Col >= 0) and (Col < 3) then
  begin
    AIndex := Row * 3 + Col;
    Result := (AIndex >= 0) and (AIndex < 12);
  end;
end;

function TJalaliPanelCalendar.YearIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
var GR: TRect; Row, Col: Integer;
begin
  Result := False; GR := GridRect;
  if not PtInRect(GR, Point(X, Y)) then Exit;
  Row := (Y - GR.Top) div (GR.Height div 3);
  Col := 3 - (X div (GR.Width div 4));
  if (Row >= 0) and (Row < 3) and (Col >= 0) and (Col < 4) then
  begin
    AIndex := Row * 4 + Col;
    Result := (AIndex >= 0) and (AIndex < 12);
  end;
end;

procedure TJalaliPanelCalendar.SelectByGridIndex(AIndex: Integer);
var Offset, CurDay, PrevDays, Y, M: Integer;
begin
  Offset := FirstDayOffset_Sat0; PrevDays := DaysInPrevMonth;
  CurDay := (AIndex - Offset) + 1;
  if CurDay < 1 then
  begin
    PrevMonthYear(Y, M); FSelectedDate.Year := Y; FSelectedDate.Month := M; FSelectedDate.Day := PrevDays + CurDay;
    SetDisplay(Y, M);
  end
  else if CurDay > DaysInDisplayMonth then
  begin
    NextMonthYear(Y, M); FSelectedDate.Year := Y; FSelectedDate.Month := M; FSelectedDate.Day := CurDay - DaysInDisplayMonth;
    SetDisplay(Y, M);
  end
  else
  begin
    FSelectedDate.Year := FDisplayYear; FSelectedDate.Month := FDisplayMonth; FSelectedDate.Day := CurDay;
    Invalidate;
  end;
  if Assigned(FOnSelectDate) then FOnSelectDate(Self, FSelectedDate);
end;

procedure TJalaliPanelCalendar.MouseMove(Shift: TShiftState; X, Y: Integer);
var NewHoverIdx, CW: Integer;
begin
  inherited;
  if PtInRect(PrevButtonRect, Point(X, Y)) or PtInRect(NextButtonRect, Point(X, Y)) or PtInRect(FooterRect, Point(X, Y)) or
     ((FViewMode = vmDays) and (PtInRect(MonthTextRect, Point(X, Y)) or PtInRect(YearTextRect, Point(X, Y)))) then
  begin
    if FHoverIndex <> -2 then begin FHoverIndex := -2; Cursor := crHandPoint; Invalidate; end;
    Exit;
  end;

  case FViewMode of
    vmDays:
    begin
      CW := Width div CGridCols;
      if DayIndexAtPos(X, Y, CW, NewHoverIdx) then
      begin
        if FHoverIndex <> NewHoverIdx then begin FHoverIndex := NewHoverIdx; Cursor := crHandPoint; Invalidate; end;
      end else if FHoverIndex <> -1 then begin FHoverIndex := -1; Cursor := crDefault; Invalidate; end;
    end;
    vmMonths:
    begin
      if MonthIndexAtPos(X, Y, NewHoverIdx) then
      begin
        if FHoverIndex <> NewHoverIdx then begin FHoverIndex := NewHoverIdx; Cursor := crHandPoint; Invalidate; end;
      end else if FHoverIndex <> -1 then begin FHoverIndex := -1; Cursor := crDefault; Invalidate; end;
    end;
    vmYears:
    begin
      if YearIndexAtPos(X, Y, NewHoverIdx) then
      begin
        if FHoverIndex <> NewHoverIdx then begin FHoverIndex := NewHoverIdx; Cursor := crHandPoint; Invalidate; end;
      end else if FHoverIndex <> -1 then begin FHoverIndex := -1; Cursor := crDefault; Invalidate; end;
    end;
  end;
end;

procedure TJalaliPanelCalendar.MouseLeave(var Message: TMessage);
begin
  inherited;
  if FHoverIndex <> -1 then begin FHoverIndex := -1; Cursor := crDefault; Invalidate; end;
end;

procedure TJalaliPanelCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Idx, CW: Integer;
begin
  inherited;
  if Button <> mbLeft then Exit;

  if PtInRect(PrevButtonRect, Point(X, Y)) then StepMonth(-1)
  else if PtInRect(NextButtonRect, Point(X, Y)) then StepMonth(1)
  else if PtInRect(FooterRect, Point(X, Y)) then
  begin
    FViewMode := vmDays;
    SetSelectedDate(TJalaliCalendar.Today);
    if Assigned(FOnSelectDate) then FOnSelectDate(Self, FSelectedDate);
  end
  else if (FViewMode = vmDays) and PtInRect(MonthTextRect, Point(X, Y)) then
  begin
    FViewMode := vmMonths;
    FHoverIndex := -1; Invalidate;
  end
  else if (FViewMode = vmDays) and PtInRect(YearTextRect, Point(X, Y)) then
  begin
    FViewMode := vmYears;
    FHoverIndex := -1; Invalidate;
  end
  else
  begin
    case FViewMode of
      vmDays:
      begin
        CW := Width div CGridCols;
        if DayIndexAtPos(X, Y, CW, Idx) then SelectByGridIndex(Idx);
      end;
      vmMonths:
      begin
        if MonthIndexAtPos(X, Y, Idx) then
        begin
          FDisplayMonth := Idx + 1;
          FViewMode := vmDays;
          FHoverIndex := -1; Invalidate;
        end;
      end;
      vmYears:
      begin
        if YearIndexAtPos(X, Y, Idx) then
        begin
          FDisplayYear := (StartYearOfDecade(FDisplayYear) - 1) + Idx;
          FViewMode := vmMonths;
          FHoverIndex := -1; Invalidate;
        end;
      end;
    end;
  end;
end;

procedure TJalaliPanelCalendar.MoveSelectionByDays(Delta: Integer);
var G: TDateTime;
begin
  if FViewMode <> vmDays then Exit;
  G := TJalaliCalendar.JalaliToDateTime(FSelectedDate.Year, FSelectedDate.Month, FSelectedDate.Day);
  G := IncDay(G, Delta);
  FSelectedDate := TJalaliCalendar.DateTimeToJalali(G);
  FDisplayYear := FSelectedDate.Year; FDisplayMonth := FSelectedDate.Month;
  Invalidate;
end;

procedure TJalaliPanelCalendar.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  case Key of
    VK_LEFT:  MoveSelectionByDays(-1);
    VK_RIGHT: MoveSelectionByDays(1);
    VK_UP:    MoveSelectionByDays(-7);
    VK_DOWN:  MoveSelectionByDays(7);
  end;
end;

procedure TJalaliPanelCalendar.SetSelectedDate(const Value: TJalaliDate);
begin
  FSelectedDate := Value;
  FDisplayYear := FSelectedDate.Year;
  FDisplayMonth := FSelectedDate.Month;
  Invalidate;
end;


end.
