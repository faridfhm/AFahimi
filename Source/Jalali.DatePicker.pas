unit Jalali.DatePicker;

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
  Vcl.ImgList,
  Data.DB,
  Vcl.DBCtrls,
  Jalali.Calendar,
  Jalali.Consts;

type
  TDateValueMode = (vmJalali, vmMiladi);

  TJalaliDateChangeEvent = procedure(Sender: TObject; const ADate: TJalaliDate) of object;
  TJalaliValidationErrorEvent = procedure(Sender: TObject; const InvalidText: string; var KeepFocus: Boolean) of object;

  TCalendarViewMode = (vmDays, vmMonths, vmYears);

  TJalaliPopupCalendar = class(TCustomControl)
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
    procedure SetSelectedDate(const ADate: TJalaliDate);

    property SelectedDate: TJalaliDate read FSelectedDate;
    property OnSelectDate: TJalaliDateChangeEvent read FOnSelectDate write FOnSelectDate;
    property HoverIndex: Integer read FHoverIndex write FHoverIndex;
  end;

  TJalaliDropDownForm = class(TForm)
  private
    FCalendar: TJalaliPopupCalendar;
    procedure WMActivate(var Message: TWMActivate); message WM_ACTIVATE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    property Calendar: TJalaliPopupCalendar read FCalendar;
  end;

  TJalaliDatePicker = class(TCustomControl)
  private
    FProducer: string;
    FDate: TJalaliDate;
    FIsEmpty: Boolean;
    FUseTodayIfEmpty: Boolean;
    FTextBuffer: string;
    FValidationErrorDisplay: Boolean;
    FOnValidationError: TJalaliValidationErrorEvent;

    FDropDown: TJalaliDropDownForm;
    FOnChange: TJalaliDateChangeEvent;
    FDropIcon: TPicture;

    FOwnerForm: TCustomForm;
    FOwnerFormOrgProc: TWndMethod;

    FImages: TCustomImageList;
    FImageIndex: TImageIndex;

    FDataLink: TFieldDataLink;
    FValueMode: TDateValueMode;
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure SetValueMode(Value: TDateValueMode);

    function GetDateTime: TDateTime;
    function GetValue: string;
    procedure SetValue(const NewValue: string);
    procedure SetDate(const Value: TJalaliDate);
    procedure SetDateTime(const Value: TDateTime);
    procedure SetDropIcon(const Value: TPicture);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);

    procedure PopupDateSelected(Sender: TObject; const ADate: TJalaliDate);
    procedure ToggleDropDown;
    procedure CloseDropDown;

    procedure HookOwnerForm;
    procedure UnhookOwnerForm;
    procedure OwnerFormWndProc(var Message: TMessage);

    function GetDropButtonWidth: Integer;
    function DropButtonRect: TRect;
    function TextRect: TRect;
    procedure DrawCalendarIcon(const R: TRect);
    procedure DropIconChanged(Sender: TObject);
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;

   procedure WMKillFocus(var Message: TWMKillFocus);
   procedure CMCancelMode(var Message: TMessage);

    procedure SyncTextBuffer;
    function IsValidJalaliStr(const S: string; out ADate: TJalaliDate): Boolean;
    procedure UpdateCaretPosition(AtStart: Boolean = False);
    procedure ClearDate;
    procedure SetUseTodayIfEmpty(Value: Boolean);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Resize; override;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Date: TJalaliDate read FDate write SetDate;
    property Value: string read GetValue write SetValue;
    property IsEmpty: Boolean read FIsEmpty;
  published
    property Producer: string read FProducer;
    property UseTodayIfEmpty: Boolean read FUseTodayIfEmpty write SetUseTodayIfEmpty default False;
    property ValidationErrorDisplay: Boolean read FValidationErrorDisplay write FValidationErrorDisplay default True;
    property OnValidationError: TJalaliValidationErrorEvent read FOnValidationError write FOnValidationError;

    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DataField: string read GetDataField write SetDataField;
    property ValueMode: TDateValueMode read FValueMode write SetValueMode default vmJalali;

    property DateTime: TDateTime read GetDateTime write SetDateTime;
    property DropIcon: TPicture read FDropIcon write SetDropIcon;

    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;

    property Align;
    property Anchors;
    property BiDiMode;
    property Color default clWindow;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;

    property OnChange: TJalaliDateChangeEvent read FOnChange write FOnChange;
  end;

//procedure Register;

implementation

const
  CGridRows = 6;
  CGridCols = 7;
  CTotalCells = CGridRows * CGridCols;
  C_PRODUCER_TEXT     = 'AFSoft2010@gmail.com';
procedure TJalaliDatePicker.CMCancelMode(var Message: TMessage);
begin
  inherited;
  if Assigned(FDropDown) and FDropDown.Visible then
  begin
    // با استفاده از TCMCancelMode به Sender دسترسی پیدا می‌کنیم
    if (TCMCancelMode(Message).Sender <> Self) and
       (TCMCancelMode(Message).Sender <> FDropDown) and
       (TCMCancelMode(Message).Sender <> FDropDown.Calendar) then
    begin
      CloseDropDown;
    end;
  end;
end;

procedure TJalaliDatePicker.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  if Assigned(FDropDown) and FDropDown.Visible then
  begin
    // بررسی می‌کنیم که اگر فوکوس به پنجره‌ای غیر از خود پاپ‌آپ یا فرزندانش منتقل شده باشد، آنگاه بسته شود
    if (Message.FocusedWnd <> FDropDown.Handle) and
       not Winapi.Windows.IsChild(FDropDown.Handle, Message.FocusedWnd) then
    begin
      CloseDropDown;
    end;
  end;
end;



function SameJalaliDate(const A, B: TJalaliDate): Boolean;
begin
  Result := (A.Year = B.Year) and (A.Month = B.Month) and (A.Day = B.Day);
end;

function JalaliToDisplayText(const ADate: TJalaliDate): string;
begin
  Result := Format('%.4d/%.2d/%.2d', [ADate.Year, ADate.Month, ADate.Day]);
end;

function JalaliToLongText(const ADate: TJalaliDate): string;
begin
  Result := Format('%d %s %d', [ADate.Day, JalaliMonthNames[ADate.Month], ADate.Year]);
end;

{ TJalaliPopupCalendar }

constructor TJalaliPopupCalendar.Create(AOwner: TComponent);
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
end;

procedure TJalaliPopupCalendar.AdjustDimensions;
var
  CW, RequiredWidth, RequiredHeight: Integer;
begin
  EnsureDisplayInitialized;
  CW := GetMaxHeaderCellWidth;
  RequiredWidth := CW * CGridCols;
  RequiredHeight := FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight) + FFooterHeight;

  SetBounds(Left, Top, RequiredWidth, RequiredHeight);
  if Parent is TForm then
  begin
    TForm(Parent).ClientWidth := RequiredWidth;
    TForm(Parent).ClientHeight := RequiredHeight;
  end;
end;

procedure TJalaliPopupCalendar.EnsureDisplayInitialized;
begin
  if (FDisplayYear = 0) or (FDisplayMonth = 0) then
  begin
    FSelectedDate := TJalaliCalendar.Today;
    FDisplayYear := FSelectedDate.Year;
    FDisplayMonth := FSelectedDate.Month;
  end;
end;

function TJalaliPopupCalendar.GetMaxHeaderCellWidth: Integer;
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

function TJalaliPopupCalendar.HeaderRect: TRect;
begin
  Result := Rect(0, 0, Width, FHeaderHeight);
end;

function TJalaliPopupCalendar.MonthTextRect: TRect;
var Middle: Integer;
begin
  Middle := Width div 2;
  Result := Rect(Middle, 0, Middle + 65, FHeaderHeight);
end;

function TJalaliPopupCalendar.YearTextRect: TRect;
var Middle: Integer;
begin
  Middle := Width div 2;
  Result := Rect(Middle - 65, 0, Middle, FHeaderHeight);
end;

function TJalaliPopupCalendar.WeekHeaderRect: TRect;
begin
  if FViewMode = vmDays then
    Result := Rect(0, FHeaderHeight, Width, FHeaderHeight + FWeekHeaderHeight)
  else
    Result := Rect(0, FHeaderHeight, 0, FHeaderHeight);
end;

function TJalaliPopupCalendar.GridRect: TRect;
begin
  if FViewMode = vmDays then
    Result := Rect(0, FHeaderHeight + FWeekHeaderHeight, Width, FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight))
  else
    Result := Rect(0, FHeaderHeight, Width, FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight));
end;

function TJalaliPopupCalendar.FooterRect: TRect;
begin
  Result := Rect(0, FHeaderHeight + FWeekHeaderHeight + (CGridRows * FCellHeight), Width, Height);
end;

function TJalaliPopupCalendar.PrevButtonRect: TRect;
begin
  Result := Rect(Width - 30, 6, Width - 6, FHeaderHeight - 6);
end;

function TJalaliPopupCalendar.NextButtonRect: TRect;
begin
  Result := Rect(6, 6, 30, FHeaderHeight - 6);
end;

function TJalaliPopupCalendar.VisualColOfLogical(ALogicalCol: Integer): Integer;
begin
  Result := (CGridCols - 1) - ALogicalCol;
end;

function TJalaliPopupCalendar.LogicalColOfVisual(AVisualCol: Integer): Integer;
begin
  Result := (CGridCols - 1) - AVisualCol;
end;

function TJalaliPopupCalendar.GetCellRect(ALogicalCol, ARow, CellW: Integer): TRect;
var
  VCol, L, T: Integer;
begin
  VCol := VisualColOfLogical(ALogicalCol);
  L := VCol * CellW;
  T := FHeaderHeight + FWeekHeaderHeight + (ARow * FCellHeight);
  Result := Rect(L, T, L + CellW, T + FCellHeight);
end;

//function TJalaliPopupCalendar.LogicalColAt(X, CellW: Integer): Integer;
//begin
//  if CellW <= 0 then Exit(-1);
//  Result := LogicalColOfVisual(X div CellW);
//end;
 function TJalaliPopupCalendar.LogicalColAt(X, CellW: Integer): Integer;
var
  VCol: Integer;
begin
  if CellW <= 0 then Exit(-1);

  VCol := X div CellW;

  // محدود کردن ستون بصری برای پیکسل‌های باقی‌مانده در لبه تقویم
  if VCol >= CGridCols then
    VCol := CGridCols - 1;

  Result := LogicalColOfVisual(VCol);
end;
function TJalaliPopupCalendar.DaysInDisplayMonth: Integer;
begin
  Result := TJalaliCalendar.DaysInMonth(FDisplayYear, FDisplayMonth);
end;

function TJalaliPopupCalendar.StartYearOfDecade(AYear: Integer): Integer;
begin
  Result := (AYear div 10) * 10;
end;

procedure TJalaliPopupCalendar.Paint;
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
  end
  else if FViewMode = vmYears then
  begin
    R := GridRect;
    W := R.Width div 4;
    H := R.Height div 3;
    StartY := StartYearOfDecade(FDisplayYear) - 1;
    for Index := 0 to 11 do
    begin
      MRow := Index div 4;
      MCol := 3 - (Index mod 4);
      CR := Rect(R.Left + MCol * W, R.Top + MRow * H, R.Left + (MCol + 1) * W, R.Top + (MRow + 1) * H);
      InflateRect(CR, -4, -4);
      CurY := StartY + Index;

      Canvas.Brush.Style := bsSolid;
      if FDisplayYear = CurY then
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

      if (Index = 0) or (Index = 11) then TextColor := FInactiveColor else TextColor := Font.Color;
      DrawCenteredText(IntToStr(CurY), CR, TextColor, False);
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

function TJalaliPopupCalendar.PrevMonthYear(out AYear, AMonth: Integer): Boolean;
begin
  AYear := FDisplayYear; AMonth := FDisplayMonth - 1;
  if AMonth < 1 then begin AMonth := 12; Dec(AYear); end;
  Result := True;
end;

function TJalaliPopupCalendar.NextMonthYear(out AYear, AMonth: Integer): Boolean;
begin
  AYear := FDisplayYear; AMonth := FDisplayMonth + 1;
  if AMonth > 12 then begin AMonth := 1; Inc(AYear); end;
  Result := True;
end;

function TJalaliPopupCalendar.DaysInPrevMonth: Integer;
var Y, M: Integer;
begin
  PrevMonthYear(Y, M); Result := TJalaliCalendar.DaysInMonth(Y, M);
end;

procedure TJalaliPopupCalendar.DrawArrowLeft(const R: TRect);
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

procedure TJalaliPopupCalendar.DrawArrowRight(const R: TRect);
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

procedure TJalaliPopupCalendar.DrawCenteredText(const S: string; const R: TRect; AColor: TColor; ABold: Boolean);
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

function TJalaliPopupCalendar.FirstDayOffset_Sat0: Integer;
begin
  Result := DayOfWeek(TJalaliCalendar.JalaliToDateTime(FDisplayYear, FDisplayMonth, 1)) mod 7;
end;

procedure TJalaliPopupCalendar.Resize;
begin
  inherited; Invalidate;
end;

procedure TJalaliPopupCalendar.SetDisplay(AYear, AMonth: Integer);
begin
  FDisplayYear := AYear; FDisplayMonth := AMonth; Invalidate;
end;

procedure TJalaliPopupCalendar.StepMonth(Delta: Integer);
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

function TJalaliPopupCalendar.DayIndexAtPos(X, Y, CellW: Integer; out AIndex: Integer): Boolean;
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

// ... بقیه متدهای کامپوننت تقویم پاپ‌آپ بدون تغییر باقی می‌مانند ...
//function TJalaliPopupCalendar.MonthIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
//var GR: TRect; Row, Col: Integer;
//begin
//  Result := False; GR := GridRect;
//  if not PtInRect(GR, Point(X, Y)) then Exit;
//  Row := (Y - GR.Top) div (GR.Height div 4);
//  Col := 2 - (X div (GR.Width div 3));
//  if (Row >= 0) and (Row < 4) and (Col >= 0) and (Col < 3) then
//  begin
//    AIndex := Row * 3 + Col;
//    Result := (AIndex >= 0) and (AIndex < 12);
//  end;
//end;
function TJalaliPopupCalendar.MonthIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
var
  GR: TRect;
  Row, Col, CellW, CellH: Integer;
begin
  Result := False;
  GR := GridRect;

  if not PtInRect(GR, Point(X, Y)) then Exit;

  CellH := GR.Height div 4;
  CellW := GR.Width div 3;
  if (CellW = 0) or (CellH = 0) then Exit;

  Row := (Y - GR.Top) div CellH;
  if Row > 3 then Row := 3; // جلوگیری از خطای لبه پایین

  Col := (X - GR.Left) div CellW;
  if Col > 2 then Col := 2; // جلوگیری از خطای لبه‌ها
  Col := 2 - Col; // راست‌به‌چپ (RTL)

  if (Row >= 0) and (Row < 4) and (Col >= 0) and (Col < 3) then
  begin
    AIndex := Row * 3 + Col;
    Result := (AIndex >= 0) and (AIndex < 12);
  end;
end;


//function TJalaliPopupCalendar.YearIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
//var GR: TRect; Row, Col: Integer;
//begin
//  Result := False; GR := GridRect;
//  if not PtInRect(GR, Point(X, Y)) then Exit;
//  Row := (Y - GR.Top) div (GR.Height div 3);
//  Col := 3 - (X div (GR.Width div 4));
//  if (Row >= 0) and (Row < 3) and (Col >= 0) and (Col < 4) then
//  begin
//    AIndex := Row * 4 + Col;
//    Result := (AIndex >= 0) and (AIndex < 12);
//  end;
//end;
   function TJalaliPopupCalendar.YearIndexAtPos(X, Y: Integer; out AIndex: Integer): Boolean;
var
  GR: TRect;
  Row, Col, CellW, CellH: Integer;
begin
  Result := False;
  GR := GridRect;

  if not PtInRect(GR, Point(X, Y)) then Exit;

  CellH := GR.Height div 3;
  CellW := GR.Width div 4;
  if (CellW = 0) or (CellH = 0) then Exit;

  Row := (Y - GR.Top) div CellH;
  if Row > 2 then Row := 2; // جلوگیری از خطای لبه پایین

  Col := (X - GR.Left) div CellW;
  if Col > 3 then Col := 3; // جلوگیری از خطای لبه‌ها
  Col := 3 - Col; // راست‌به‌چپ (RTL)

  if (Row >= 0) and (Row < 3) and (Col >= 0) and (Col < 4) then
  begin
    AIndex := Row * 4 + Col;
    Result := (AIndex >= 0) and (AIndex < 12);
  end;
end;

procedure TJalaliPopupCalendar.SelectByGridIndex(AIndex: Integer);
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

procedure TJalaliPopupCalendar.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TJalaliPopupCalendar.MouseLeave(var Message: TMessage);
begin
  inherited;
  if FHoverIndex <> -1 then begin FHoverIndex := -1; Cursor := crDefault; Invalidate; end;
end;

procedure TJalaliPopupCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TJalaliPopupCalendar.MoveSelectionByDays(Delta: Integer);
var G: TDateTime;
begin
  if FViewMode <> vmDays then Exit;
  G := TJalaliCalendar.JalaliToDateTime(FSelectedDate.Year, FSelectedDate.Month, FSelectedDate.Day);
  G := IncDay(G, Delta);
  FSelectedDate := TJalaliCalendar.DateTimeToJalali(G);
  FDisplayYear := FSelectedDate.Year; FDisplayMonth := FSelectedDate.Month;
  Invalidate;
end;

procedure TJalaliPopupCalendar.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  case Key of
    VK_LEFT:  MoveSelectionByDays(-1);
    VK_RIGHT: MoveSelectionByDays(1);
    VK_UP:    MoveSelectionByDays(-7);
    VK_DOWN:  MoveSelectionByDays(7);
  end;
end;

procedure TJalaliPopupCalendar.SetSelectedDate(const ADate: TJalaliDate);
begin
  FSelectedDate := ADate;
  FDisplayYear := FSelectedDate.Year;
  FDisplayMonth := FSelectedDate.Month;
  Invalidate;
end;

{ TJalaliDropDownForm }

constructor TJalaliDropDownForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
begin
  inherited CreateNew(AOwner, Dummy);
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  FCalendar := TJalaliPopupCalendar.Create(Self);
  FCalendar.Parent := Self;
  FCalendar.Align := alClient;
end;

procedure TJalaliDropDownForm.CreateParams(var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_POPUP;
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
end;

procedure TJalaliDropDownForm.Paint;
begin
  inherited;
  Canvas.Pen.Color := $00CFCFCF;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TJalaliDropDownForm.WMActivate(var Message: TWMActivate);
begin
  inherited;
  if Message.Active = WA_INACTIVE then
    Visible := False;
end;

{ TJalaliDatePicker }

constructor TJalaliDatePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents];
  FProducer := C_PRODUCER_TEXT;
  Width := 140;
  Height := 24;
  Color := clWindow;
  TabStop := True;

  FValidationErrorDisplay := True;
  FUseTodayIfEmpty := False;

  FDropIcon := TPicture.Create;
  FDropIcon.OnChange := DropIconChanged;
  FImageIndex := -1;

  // مقدار دهی پیش‌فرض به تاریخ روز در زمان طراحی (یا در صورت عدم فعال بودن ویژگی UseTodayIfEmpty)
  FDate := TJalaliCalendar.Today;
  FIsEmpty := False;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;

  SyncTextBuffer;
end;

destructor TJalaliDatePicker.Destroy;
begin
  UnhookOwnerForm;
  FDataLink.Free;
  FDataLink := nil;
  FDropIcon.Free;
  inherited Destroy;
end;

procedure TJalaliDatePicker.Loaded;
begin
  inherited Loaded;
  // مدیریت مقدار دهی اولیه پس از لود کامل فرم و خاصیت‌ها در زمان اجرا یا طراحی
  if FUseTodayIfEmpty then
  begin
    FIsEmpty := True;
    FTextBuffer := '';
  end
  else
  begin
    FIsEmpty := False;
    FDate := TJalaliCalendar.Today;
    SyncTextBuffer;
  end;
  Invalidate;
end;

procedure TJalaliDatePicker.SetUseTodayIfEmpty(Value: Boolean);
begin
  if FUseTodayIfEmpty <> Value then
  begin
    FUseTodayIfEmpty := Value;

    // در زمان طراحی، مقدار دهی ویژوال فوراً به‌روز شود
    if (csDesigning in ComponentState) then
    begin
      if FUseTodayIfEmpty then
      begin
        FIsEmpty := True;
        FTextBuffer := '';
      end
      else
      begin
        FDate := TJalaliCalendar.Today;
        FIsEmpty := False;
        SyncTextBuffer;
      end;
      Invalidate;
    end;
  end;
end;

procedure TJalaliDatePicker.SyncTextBuffer;
begin
  if FIsEmpty then
    FTextBuffer := ''
  else
    FTextBuffer := JalaliToDisplayText(FDate);
end;

procedure TJalaliDatePicker.ClearDate;
begin
  FIsEmpty := True;
  FTextBuffer := '';
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self, FDate);
end;

function TJalaliDatePicker.IsValidJalaliStr(const S: string; out ADate: TJalaliDate): Boolean;
var
  Parts: TArray<string>;
  Y, M, D: Integer;
begin
  Result := False;
  ADate := FDate;

  if Length(S) <> 10 then Exit;
  if (S[5] <> '/') or (S[8] <> '/') then Exit;

  Parts := S.Split(['/']);
  if Length(Parts) <> 3 then Exit;

  if TryStrToInt(Parts[0], Y) and TryStrToInt(Parts[1], M) and TryStrToInt(Parts[2], D) then
  begin
    if (Y < 1) or (M < 1) or (M > 12) or (D < 1) then Exit;
    if D <= TJalaliCalendar.DaysInMonth(Y, M) then
    begin
      ADate.Year := Y;
      ADate.Month := M;
      ADate.Day := D;
      Result := True;
    end;
  end;
end;

procedure TJalaliDatePicker.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FDataLink <> nil) and (AComponent = DataSource) then
    DataSource := nil;
  if (Operation = opRemove) and (AComponent = FImages) then
    Images := nil;
end;

function TJalaliDatePicker.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TJalaliDatePicker.SetDataSource(Value: TDataSource);
begin
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    FDataLink.DataSource := Value;
  if Value <> nil then
    Value.FreeNotification(Self);
end;

function TJalaliDatePicker.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

procedure TJalaliDatePicker.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

procedure TJalaliDatePicker.SetValueMode(Value: TDateValueMode);
begin
  if FValueMode <> Value then
  begin
    FValueMode := Value;
    DataChange(Self);
  end;
end;

procedure TJalaliDatePicker.SetImages(const Value: TCustomImageList);
begin
  if FImages <> Value then
  begin
    if FImages <> nil then
      FImages.RemoveFreeNotification(Self);
    FImages := Value;
    if FImages <> nil then
      FImages.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TJalaliDatePicker.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Invalidate;
  end;
end;

procedure TJalaliDatePicker.DataChange(Sender: TObject);
var
  S: string;
  DT: TDateTime;
  JD: TJalaliDate;
begin
  if (FDataLink.Field <> nil) and not (FDataLink.Field.IsNull) then
  begin
    FIsEmpty := False;
    if FDataLink.Field.DataType in [ftDate, ftDateTime] then
    begin
      SetDateTime(FDataLink.Field.AsDateTime);
    end
    else
    begin
      S := FDataLink.Field.AsString;
      if Length(S) = 10 then
      begin
        try
          if FValueMode = vmJalali then
          begin
            JD.Year := StrToInt(Copy(S, 1, 4));
            JD.Month := StrToInt(Copy(S, 6, 2));
            JD.Day := StrToInt(Copy(S, 9, 2));
            FDate := JD;
          end
          else
          begin
            DT := EncodeDate(StrToInt(Copy(S, 1, 4)), StrToInt(Copy(S, 6, 2)), StrToInt(Copy(S, 9, 2)));
            FDate := TJalaliCalendar.DateTimeToJalali(DT);
          end;
        except
          FDate := TJalaliCalendar.Today;
        end;
      end;
    end;
  end
  else
  begin
    // در زمان اجرا، فیلدهای تهی دیتابیس همواره خالی باقی می‌مانند مگر در حالت طراحی بدون UseTodayIfEmpty
    if (csDesigning in ComponentState) and (not FUseTodayIfEmpty) then
    begin
      FDate := TJalaliCalendar.Today;
      FIsEmpty := False;
    end
    else
    begin
      FIsEmpty := True;
    end;
  end;
  SyncTextBuffer;
  Invalidate;
end;

procedure TJalaliDatePicker.UpdateData(Sender: TObject);
begin
  if (FDataLink.Field <> nil) and (FDataLink.CanModify) then
  begin
    if FIsEmpty then
    begin
      FDataLink.Field.Clear;
    end
    else
    begin
      if FDataLink.Field.DataType in [ftDate, ftDateTime] then
        FDataLink.Field.AsDateTime := GetDateTime
      else
        FDataLink.Field.AsString := GetValue;
    end;
  end;
end;

function TJalaliDatePicker.GetDateTime: TDateTime;
begin
  if FIsEmpty then
    Result := 0
  else
    Result := TJalaliCalendar.JalaliToDateTime(FDate.Year, FDate.Month, FDate.Day);
end;

function TJalaliDatePicker.GetValue: string;
begin
  if FIsEmpty then
    Result := ''
  else if FValueMode = vmMiladi then
    Result := FormatDateTime('YYYY/MM/DD', GetDateTime)
  else
    Result := JalaliToDisplayText(FDate);
end;

procedure TJalaliDatePicker.SetValue(const NewValue: string);
var
  ParsedDate: TJalaliDate;
  DT: TDateTime;
  Y, M, D: Integer;
  TrimmedValue: string;
begin
  TrimmedValue := Trim(NewValue);

  if TrimmedValue = '' then
  begin
    FIsEmpty := True;
    ClearDate;

    if FDataLink.Edit then
    begin
      FDataLink.Modified;
      FDataLink.UpdateRecord;
    end;
    Exit;
  end;

  if IsValidJalaliStr(TrimmedValue, ParsedDate) then
  begin
    FIsEmpty := False;
    if FDataLink.Edit then
    begin
      SetDate(ParsedDate);
      FDataLink.Modified;
      FDataLink.UpdateRecord;
    end
    else
    begin
      SetDate(ParsedDate);
    end;
  end
  else if FValueMode = vmMiladi then
  begin
    if (Length(TrimmedValue) = 10) and (TrimmedValue[5] = '/') and (TrimmedValue[8] = '/') then
    begin
      try
        Y := StrToInt(Copy(TrimmedValue, 1, 4));
        M := StrToInt(Copy(TrimmedValue, 6, 2));
        D := StrToInt(Copy(TrimmedValue, 9, 2));
        DT := EncodeDate(Y, M, D);

        FIsEmpty := False;
        if FDataLink.Edit then
        begin
          SetDateTime(DT);
          FDataLink.Modified;
          FDataLink.UpdateRecord;
        end
        else
        begin
          SetDateTime(DT);
        end;
      except
      end;
    end;
  end;
end;

procedure TJalaliDatePicker.SetDate(const Value: TJalaliDate);
begin
  FIsEmpty := False;
  if not SameJalaliDate(FDate, Value) then
  begin
    FDate := Value;
    SyncTextBuffer;
    Invalidate;
    if Assigned(FOnChange) then
      FOnChange(Self, FDate);
  end;
end;

procedure TJalaliDatePicker.SetDateTime(const Value: TDateTime);
begin
  if Value = 0 then
  begin
    ClearDate;
  end
  else
    SetDate(TJalaliCalendar.DateTimeToJalali(Value));
end;

procedure TJalaliDatePicker.SetDropIcon(const Value: TPicture);
begin
  FDropIcon.Assign(Value);
end;

procedure TJalaliDatePicker.DropIconChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TJalaliDatePicker.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

function TJalaliDatePicker.GetDropButtonWidth: Integer;
begin
  if Assigned(FImages) then
    Result := FImages.Width + 8
  else if (FDropIcon.Graphic <> nil) and (not FDropIcon.Graphic.Empty) then
    Result := FDropIcon.Width + 8
  else
    Result := 24;
end;

function TJalaliDatePicker.DropButtonRect: TRect;
begin
  Result := Rect(0, 0, GetDropButtonWidth, Height);
end;

function TJalaliDatePicker.TextRect: TRect;
var
  BtnW: Integer;
begin
  BtnW := GetDropButtonWidth;
  Result := Rect(BtnW + 4, 2, Width - 4, Height - 2);
end;

procedure TJalaliDatePicker.DrawCalendarIcon(const R: TRect);
var
  CX, CY, ImgX, ImgY: Integer;
begin
  if Assigned(FImages) and (FImageIndex >= 0) and (FImageIndex < FImages.Count) then
  begin
    ImgX := R.Left + (R.Width - FImages.Width) div 2;
    ImgY := R.Top + (R.Height - FImages.Height) div 2;
    FImages.Draw(Canvas, ImgX, ImgY, FImageIndex, Enabled);
  end
  else if (FDropIcon.Graphic <> nil) and (not FDropIcon.Graphic.Empty) then
  begin
    Canvas.Draw(R.Left + (R.Width - FDropIcon.Width) div 2,
                R.Top + (R.Height - FDropIcon.Height) div 2, FDropIcon.Graphic);
  end
  else
  begin
    CX := (R.Left + R.Right) div 2;
    CY := (R.Top + R.Bottom) div 2;
    Canvas.Pen.Color := clGrayText;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(CX - 6, CY - 5, CX + 7, CY + 7);
    Canvas.MoveTo(CX - 6, CY - 1); Canvas.LineTo(CX + 7, CY - 1);
    Canvas.MoveTo(CX - 3, CY - 5); Canvas.LineTo(CX - 3, CY - 3);
    Canvas.MoveTo(CX + 3, CY - 5); Canvas.LineTo(CX + 3, CY - 3);
  end;
end;

procedure TJalaliDatePicker.Paint;
var
  R, RText: TRect;
  S: string;
  FormatFlags: TTextFormat;
  BtnW: Integer;
begin
  inherited;
  Canvas.Brush.Color := Color;
  if Enabled then Canvas.Brush.Color := Color else Canvas.Brush.Color := clBtnFace;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  Canvas.Pen.Color := $00CFCFCF;
  Canvas.Rectangle(0, 0, Width, Height);

  BtnW := GetDropButtonWidth;

  if UseRightToLeftAlignment then
  begin
    R := Rect(Width - BtnW, 0, Width, Height);
    RText := Rect(4, 2, Width - (BtnW + 4), Height - 2);
  end
  else
  begin
    R := Rect(0, 0, BtnW, Height);
    RText := Rect(BtnW + 4, 2, Width - 4, Height - 2);
  end;

  Canvas.Brush.Color := $00F3F3F3;
  Canvas.FillRect(Rect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1));
  Canvas.Pen.Color := $00CFCFCF;
  if UseRightToLeftAlignment then
  begin
    Canvas.MoveTo(R.Left, R.Top);
    Canvas.LineTo(R.Left, R.Bottom);
  end
  else
  begin
    Canvas.MoveTo(R.Right, R.Top);
    Canvas.LineTo(R.Right, R.Bottom);
  end;

  DrawCalendarIcon(R);

  Canvas.Font.Assign(Self.Font);
  if not Enabled then Canvas.Font.Color := clGrayText;

  if Focused then
    S := FTextBuffer
  else if FIsEmpty then
    S := ''
  else
    S := JalaliToDisplayText(FDate);

  Canvas.Brush.Style := bsClear;

  if UseRightToLeftAlignment then
    FormatFlags := [tfLeft, tfVerticalCenter, tfSingleLine]
  else
    FormatFlags := [tfRight, tfVerticalCenter, tfSingleLine];

  Canvas.TextRect(RText, S, FormatFlags);

  if Focused then
  begin
    R := ClientRect;
    InflateRect(R, -2, -2);
    Canvas.Pen.Color := clHighlight;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(R);
  end;
end;

procedure TJalaliDatePicker.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DropRect: TRect;
  BtnW: Integer;
begin
  inherited;
  if Button = mbLeft then
  begin
    if CanFocus then
    begin
      SetFocus;
      Invalidate;
    end;

    BtnW := GetDropButtonWidth;
    if UseRightToLeftAlignment then
      DropRect := Rect(Width - BtnW, 0, Width, Height)
    else
      DropRect := Rect(0, 0, BtnW, Height);

    if PtInRect(DropRect, Point(X, Y)) then
      ToggleDropDown;
  end;
end;

procedure TJalaliDatePicker.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTCHARS or DLGC_WANTARROWS or DLGC_HASSETSEL;
end;

procedure TJalaliDatePicker.UpdateCaretPosition(AtStart: Boolean);
var
  TextW: Integer;
begin
  if not Focused then Exit;

  if AtStart or FIsEmpty then
    TextW := 0
  else
  begin
    Canvas.Font.Assign(Self.Font);
    TextW := Canvas.TextWidth(FTextBuffer);
  end;

  if UseRightToLeftAlignment then
    SetCaretPos(4 + TextW, 3)
  else
    SetCaretPos(Max(4, Width - GetDropButtonWidth - 6 - TextW), 3);
end;

procedure TJalaliDatePicker.KeyPress(var Key: Char);
var
  ParsedDate: TJalaliDate;
begin
  inherited KeyPress(Key);

  if Key < #32 then Exit;

  if not CharInSet(Key, ['0'..'9']) then
  begin
    Key := #0;
    Exit;
  end;

  if Length(FTextBuffer) >= 10 then
  begin
    Key := #0;
    Exit;
  end;

  if not FDataLink.Editing then
    FDataLink.Edit;

  FIsEmpty := False;
  FTextBuffer := FTextBuffer + Key;

  if (Length(FTextBuffer) = 4) or (Length(FTextBuffer) = 7) then
    FTextBuffer := FTextBuffer + '/';

  Invalidate;
  UpdateCaretPosition(False);

  if (Length(FTextBuffer) = 10) and Assigned(FDropDown) and FDropDown.Visible then
  begin
    if IsValidJalaliStr(FTextBuffer, ParsedDate) then
    begin
      FDropDown.Calendar.SetSelectedDate(ParsedDate);
      FDropDown.Calendar.HoverIndex := (ParsedDate.Day - 1) + FDropDown.Calendar.FirstDayOffset_Sat0;
    end;
  end;

  Key := #0;
end;

procedure TJalaliDatePicker.KeyDown(var Key: Word; Shift: TShiftState);
var
  L: Integer;
begin
  if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    ToggleDropDown;
    Key := 0;
    Exit;
  end;

  if Key = VK_RETURN then
  begin
    DoExit;
    Key := 0;
    Exit;
  end;

  if Assigned(FDropDown) and FDropDown.Visible then
  begin
    if Key in [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT] then
    begin
      FDropDown.Calendar.KeyDown(Key, Shift);
      Key := 0;
      Exit;
    end;
  end;

  // پاک کردن کامل تاریخ با زدن Delete زمانی که فیلد هنوز فوکوس دارد و کاراکتری ندارد
  if (Key = VK_DELETE) and (FTextBuffer = '') then
  begin
    if not FDataLink.Editing then FDataLink.Edit;
    ClearDate;
    Key := 0;
    Exit;
  end;

  if Key = VK_BACK then
  begin
    L := Length(FTextBuffer);
    if L > 0 then
    begin
      if not FDataLink.Editing then
        FDataLink.Edit;

      if (L = 6) or (L = 9) then
        Delete(FTextBuffer, L - 1, 2)
      else
        Delete(FTextBuffer, L, 1);

      if FTextBuffer = '' then
      begin
        FIsEmpty := True; // در زمان ویرایش با بک‌اسپیس، همواره فیلد خالی می‌شود تا کاربر بتواند فیلد را کاملا پاک کند
      end;

      Invalidate;
      UpdateCaretPosition(False);
    end;
    Key := 0;
    Exit;
  end;

  inherited KeyDown(Key, Shift);
end;

procedure TJalaliDatePicker.DoEnter;
begin
  inherited DoEnter;
  SyncTextBuffer;

  CreateCaret(Handle, 0, 2, Height - 6);
  UpdateCaretPosition(FIsEmpty);
  ShowCaret(Handle);

  Invalidate;
end;

procedure TJalaliDatePicker.DoExit;
var
  ParsedDate: TJalaliDate;
  KeepFocus: Boolean;
begin
  HideCaret(Handle);
  DestroyCaret;

  KeepFocus := False;

  if FTextBuffer = '' then
  begin
    FIsEmpty := True;
    if FDataLink.Edit then
    begin
      FDataLink.Modified;
      FDataLink.UpdateRecord;
    end;
  end
  else if IsValidJalaliStr(FTextBuffer, ParsedDate) then
  begin
    FIsEmpty := False;
    if not SameJalaliDate(FDate, ParsedDate) then
    begin
      if FDataLink.Edit then
      begin
        SetDate(ParsedDate);
        FDataLink.Modified;
        FDataLink.UpdateRecord;
      end
      else
        SetDate(ParsedDate);
    end;
  end
  else
  begin
    if Assigned(FOnValidationError) then
    begin
      FOnValidationError(Self, FTextBuffer, KeepFocus);
    end
    else if FValidationErrorDisplay then
    begin
      Application.MessageBox(
        PChar(Format('تاریخ وارد شده (%s) معتبر نمی‌باشد. لطفاً یک تاریخ صحیح وارد کنید.', [FTextBuffer])),
        'خطای اعتبارسنجی',
        MB_OK or MB_ICONWARNING or MB_RTLREADING or MB_RIGHT
      );
      KeepFocus := True;
    end;

    if KeepFocus then
    begin
      if CanFocus then
      begin
        SetFocus;
        Exit;
      end;
    end
    else
    begin
      SyncTextBuffer;
    end;
  end;

  inherited DoExit;
  Invalidate;
end;

procedure TJalaliDatePicker.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TJalaliDatePicker.HookOwnerForm;
begin
  // فرم مالک را پیدا می‌کنیم و در صورتی که قبلاً هوک نشده، WindowProc آن را
  // موقتاً به متد خودمان تغییر می‌دهیم تا از جابجایی/تغییر اندازهٔ فرم مطلع شویم
  FOwnerForm := GetParentForm(Self);
  if Assigned(FOwnerForm) and not Assigned(FOwnerFormOrgProc) then
  begin
    FOwnerFormOrgProc := FOwnerForm.WindowProc;
    FOwnerForm.WindowProc := OwnerFormWndProc;
  end;
end;

procedure TJalaliDatePicker.UnhookOwnerForm;
begin
  if Assigned(FOwnerForm) and Assigned(FOwnerFormOrgProc) then
  begin
    FOwnerForm.WindowProc := FOwnerFormOrgProc;
    FOwnerFormOrgProc := nil;
  end;
  FOwnerForm := nil;
end;

procedure TJalaliDatePicker.OwnerFormWndProc(var Message: TMessage);
begin
  // ابتدا اجازه می‌دهیم پردازش عادی پیام توسط فرم انجام شود
  if Assigned(FOwnerFormOrgProc) then
    FOwnerFormOrgProc(Message);

  case Message.Msg of
    WM_WINDOWPOSCHANGING, WM_MOVE, WM_SIZE:
      begin
        // به محض شروع جابجایی/تغییر اندازهٔ فرم، دراپ‌داون را می‌بندیم
        if Assigned(FDropDown) and FDropDown.Visible then
          CloseDropDown;
      end;
  end;
end;

procedure TJalaliDatePicker.ToggleDropDown;
var
  P: TPoint;
  Offset, TargetIndex: Integer;
begin
  if Assigned(FDropDown) and FDropDown.Visible then
  begin
    CloseDropDown;
    Exit;
  end;

  if not Assigned(FDropDown) then
  begin
    FDropDown := TJalaliDropDownForm.CreateNew(Self);
    FDropDown.PopupMode := pmExplicit;
    FDropDown.PopupParent := GetParentForm(Self);
    FDropDown.Calendar.OnSelectDate := PopupDateSelected;
  end;

  FDropDown.Calendar.Font.Assign(Self.Font);

  if FIsEmpty then
    FDropDown.Calendar.SetSelectedDate(TJalaliCalendar.Today)
  else
    FDropDown.Calendar.SetSelectedDate(FDate);

  FDropDown.Calendar.AdjustDimensions;

  Offset := FDropDown.Calendar.FirstDayOffset_Sat0;
  if FIsEmpty then
    TargetIndex := (TJalaliCalendar.Today.Day - 1) + Offset
  else
    TargetIndex := (FDate.Day - 1) + Offset;

  FDropDown.Calendar.HoverIndex := TargetIndex;

  if UseRightToLeftAlignment then
    P := ClientToScreen(Point(Width - FDropDown.Width, Height))
  else
    P := ClientToScreen(Point(0, Height));

  if P.X + FDropDown.Width > Screen.Width then P.X := Screen.Width - FDropDown.Width;
  if P.X < 0 then P.X := 0;
  if P.Y + FDropDown.Height > Screen.Height then P.Y := ClientToScreen(Point(0, 0)).Y - FDropDown.Height;

  FDropDown.SetBounds(P.X, P.Y, FDropDown.Width, FDropDown.Height);

  HookOwnerForm;

Winapi.Windows.SetWindowPos(FDropDown.Handle, HWND_TOPMOST, 0, 0, 0, 0,
  SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW);
FDropDown.Visible := True;
end;

procedure TJalaliDatePicker.CloseDropDown;
begin
  if Assigned(FDropDown) then
    FDropDown.Visible := False;
  UnhookOwnerForm;
end;

procedure TJalaliDatePicker.PopupDateSelected(Sender: TObject; const ADate: TJalaliDate);
begin
  FIsEmpty := False;
  if FDataLink.Edit then
  begin
    SetDate(ADate);
    FDataLink.Modified;
    FDataLink.UpdateRecord;
  end
  else
  begin
    SetDate(ADate);
  end;
  CloseDropDown;
end;

//procedure Register;
//begin
//  RegisterComponents('Jalali DatePicker', [TJalaliDatePicker]);
//end;

end.
