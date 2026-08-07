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
  Jalali.Consts,
  Jalali.CalendarCore;

type
  TDateValueMode = (vmJalali, vmMiladi);
  TDateSelectPart = (dspYear, dspMonth, dspDay);
  TJalaliDateFormat = (jdfYYYYMMDD, jdfYYMMDD, jdfYYYYMMDD_Dash);

  TJalaliValidationErrorEvent = procedure(Sender: TObject; const InvalidText: string; var KeepFocus: Boolean) of object;

  TJalaliPopupCalendar = class(TJalaliCalendarCore)
  protected
    procedure Click; override;
  public
    procedure AdjustDimensions; override;
  end;

  TJalaliDatePicker = class;

  TJalaliDropDownForm = class(TForm)
  private
    FCalendar: TJalaliPopupCalendar;
    FPicker: TJalaliDatePicker;
    procedure WMActivate(var Message: TWMActivate); message WM_ACTIVATE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    property Calendar: TJalaliPopupCalendar read FCalendar;
    property Picker: TJalaliDatePicker read FPicker write FPicker;
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

    FDateFormat: TJalaliDateFormat;
    FBorderColor: TColor;  // ← جدید

    FDropDownWidth: Integer;
    FDropDown: TJalaliDropDownForm;
    FOnChange: TJalaliDateChangeEvent;
    FDropIcon: TPicture;

    FImages: TCustomImageList;
    FImageIndex: TImageIndex;

    FDataLink: TFieldDataLink;
    FValueMode: TDateValueMode;

    FSelectedPart: TDateSelectPart;
    FInputBuffer: string;

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure SetValueMode(Value: TDateValueMode);
    procedure SetDateFormat(Value: TJalaliDateFormat);
    procedure SetBorderColor(Value: TColor);  // ← جدید

    function GetDateTime: TDateTime;
    function GetValue: string;
    procedure SetValue(const NewValue: string);
    procedure SetDate(const Value: TJalaliDate);
    procedure SetDateTime(const Value: TDateTime);
    procedure SetDropIcon(const Value: TPicture);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetDropDownWidth(const Value: Integer);

    procedure PopupDateSelected(Sender: TObject; const ADate: TJalaliDate);
    procedure ToggleDropDown;
    procedure CloseDropDown;

    procedure HookOwnerForm;
    procedure UnhookOwnerForm;

    function GetDropButtonWidth: Integer;
    function DropButtonRect: TRect;
    function TextRect: TRect;
    procedure DrawCalendarIcon(const R: TRect);
    procedure DrawDefaultCalendarIcon(const R: TRect);
    procedure DropIconChanged(Sender: TObject);
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;

    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure CMCancelMode(var Message: TMessage); message CM_CANCELMODE;

    procedure SyncTextBuffer;
    function IsValidJalaliStr(const S: string; out ADate: TJalaliDate): Boolean;
    procedure ClearDate;
    procedure SetUseTodayIfEmpty(Value: Boolean);

    function GetPartRect(APart: TDateSelectPart): TRect;
    procedure SetSelectedPart(Value: TDateSelectPart);
    procedure AdjustPartValue(Delta: Integer);
    procedure ProcessCharInput(Ch: Char);
    function GetSeparatorChar: string;
    function GetYearString: string;

    procedure ValidateAndApplyInput;
    procedure SelectPartAt(X: Integer);
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
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
    property SelectedPart: TDateSelectPart read FSelectedPart write SetSelectedPart default dspYear;
  published
    property Producer: string read FProducer;
    property DateFormat: TJalaliDateFormat read FDateFormat write SetDateFormat default jdfYYYYMMDD;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00CFCFCF;  // ← جدید
    property UseTodayIfEmpty: Boolean read FUseTodayIfEmpty write SetUseTodayIfEmpty default False;
    property ValidationErrorDisplay: Boolean read FValidationErrorDisplay write FValidationErrorDisplay default True;
    property OnValidationError: TJalaliValidationErrorEvent read FOnValidationError write FOnValidationError;

    property DropDownWidth: Integer read FDropDownWidth write SetDropDownWidth default 0;

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

implementation

function SetWindowSubclass(hWnd: HWND; pfnSubclass: Pointer; uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): BOOL; stdcall; external 'comctl32.dll';
function DefSubclassProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; external 'comctl32.dll';
function RemoveWindowSubclass(hWnd: HWND; pfnSubclass: Pointer; uIdSubclass: UINT_PTR): BOOL; stdcall; external 'comctl32.dll';

const
  C_PRODUCER_TEXT = 'AFSoft2010@gmail.com';

var
  MouseHookHandle: HHOOK = 0;
  HookedPicker: TJalaliDatePicker = nil;

function DatePickerMouseHook(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  Info: PMouseHookStruct;
  Pt: TPoint;
  PickerRect, DropRect: TRect;
begin
  if (nCode = HC_ACTION) and (HookedPicker <> nil) and
     Assigned(HookedPicker.FDropDown) and HookedPicker.FDropDown.Visible then
  begin
    if (wParam = WM_LBUTTONDOWN) or (wParam = WM_RBUTTONDOWN) or
       (wParam = WM_MBUTTONDOWN) or (wParam = WM_NCLBUTTONDOWN) then
    begin
      Info := PMouseHookStruct(lParam);
      Pt := Info.pt;

      PickerRect.TopLeft := HookedPicker.ClientToScreen(Point(0, 0));
      PickerRect.BottomRight := HookedPicker.ClientToScreen(Point(HookedPicker.Width, HookedPicker.Height));

      DropRect.TopLeft := Point(HookedPicker.FDropDown.Left, HookedPicker.FDropDown.Top);
      DropRect.BottomRight := Point(HookedPicker.FDropDown.Left + HookedPicker.FDropDown.Width,
                                     HookedPicker.FDropDown.Top + HookedPicker.FDropDown.Height);

      if not PtInRect(PickerRect, Pt) and not PtInRect(DropRect, Pt) then
        HookedPicker.CloseDropDown;
    end;
  end;
  Result := CallNextHookEx(MouseHookHandle, nCode, wParam, lParam);
end;

function OwnerFormSubclassProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM;
  uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
var
  Picker: TJalaliDatePicker;
begin
  Picker := TJalaliDatePicker(dwRefData);

  case uMsg of
    WM_MOVE, WM_SIZE:
      begin
        if Assigned(Picker) and Assigned(Picker.FDropDown) and Picker.FDropDown.Visible then
          Picker.CloseDropDown;
      end;
  end;

  Result := DefSubclassProc(hWnd, uMsg, wParam, lParam);
end;

procedure TJalaliDatePicker.CMCancelMode(var Message: TMessage);
begin
  inherited;
  if Assigned(FDropDown) and FDropDown.Visible then
  begin
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

function JalaliToDisplayText(const ADate: TJalaliDate; AFormat: TJalaliDateFormat): string;
var
  Sep: string;
begin
  if AFormat = jdfYYYYMMDD_Dash then
    Sep := '-'
  else
    Sep := '/';

  if AFormat = jdfYYMMDD then
    Result := Format('%.2d%s%.2d%s%.2d', [ADate.Year mod 100, Sep, ADate.Month, Sep, ADate.Day])
  else
    Result := Format('%.4d%s%.2d%s%.2d', [ADate.Year, Sep, ADate.Month, Sep, ADate.Day]);
end;

{ TJalaliPopupCalendar }

procedure TJalaliPopupCalendar.Click;
begin
  inherited Click;
  if (HoverIndex >= 0) and Assigned(OnSelectDate) then
  begin
    OnSelectDate(Self, SelectedDate);
  end;
end;

procedure TJalaliPopupCalendar.AdjustDimensions;
begin
  inherited AdjustDimensions;
  if Parent is TForm then
  begin
    TForm(Parent).ClientWidth := Width;
    TForm(Parent).ClientHeight := Height;
  end;
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
  Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST or WS_EX_NOACTIVATE;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW;
end;

procedure TJalaliDropDownForm.Paint;
begin
  inherited;
  // اصلاح: استفاده از رنگ Border پیکر در صورت وجود
  if Assigned(FPicker) then
    Canvas.Pen.Color := FPicker.BorderColor
  else
    Canvas.Pen.Color := $00CFCFCF;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TJalaliDropDownForm.WMActivate(var Message: TWMActivate);
begin
  inherited;
  if (Message.Active = WA_INACTIVE) and Assigned(FPicker) then
  begin
    if (Message.ActiveWindow <> FPicker.Handle) and
       not Winapi.Windows.IsChild(Handle, Message.ActiveWindow) then
      FPicker.CloseDropDown;
  end;
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

  FDateFormat := jdfYYYYMMDD;
  FBorderColor := $00CFCFCF;  // ← جدید: مقدار پیش‌فرض
  FDropDownWidth := 0;
  FSelectedPart := dspYear;
  FInputBuffer := '';

  FValidationErrorDisplay := True;
  FUseTodayIfEmpty := False;

  FDropIcon := TPicture.Create;
  FDropIcon.OnChange := DropIconChanged;
  FImageIndex := -1;

  FDate := TJalaliCalendar.Today;
  FIsEmpty := True;

  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;

  SyncTextBuffer;
end;

destructor TJalaliDatePicker.Destroy;
begin
  UnhookOwnerForm;
  if Assigned(FDropDown) then
  begin
    CloseDropDown;
    FreeAndNil(FDropDown);
  end;
  FDataLink.Free;
  FDropIcon.Free;
  inherited Destroy;
end;

procedure TJalaliDatePicker.SetDateFormat(Value: TJalaliDateFormat);
begin
  if FDateFormat <> Value then
  begin
    FDateFormat := Value;
    SyncTextBuffer;
    Invalidate;
  end;
end;

// ← جدید: ست BorderColor
procedure TJalaliDatePicker.SetBorderColor(Value: TColor);
begin
  if FBorderColor <> Value then
  begin
    FBorderColor := Value;
    Invalidate;
  end;
end;

function TJalaliDatePicker.GetSeparatorChar: string;
begin
  if FDateFormat = jdfYYYYMMDD_Dash then
    Result := '-'
  else
    Result := '/';
end;

function TJalaliDatePicker.GetYearString: string;
begin
  if FIsEmpty then Exit('');
  if FDateFormat = jdfYYMMDD then
    Result := Format('%.2d', [FDate.Year mod 100])
  else
    Result := Format('%.4d', [FDate.Year]);
end;

procedure TJalaliDatePicker.SetDropDownWidth(const Value: Integer);
begin
  if FDropDownWidth <> Value then
  begin
    FDropDownWidth := Value;
    if Assigned(FDropDown) and FDropDown.Visible then
    begin
      if FDropDownWidth > 0 then
        FDropDown.Width := FDropDownWidth;
    end;
  end;
end;

procedure TJalaliDatePicker.SetSelectedPart(Value: TDateSelectPart);
begin
  if FSelectedPart <> Value then
  begin
    FSelectedPart := Value;
    FInputBuffer := '';
    Invalidate;
  end;
end;

function TJalaliDatePicker.GetPartRect(APart: TDateSelectPart): TRect;
var
  RText: TRect;
  YearStr, MonthStr, DayStr, SepStr: string;
  WYear, WMonth, WDay, WSep: Integer;
  CurX: Integer;
begin
  RText := TextRect;
  Canvas.Font.Assign(Self.Font);

  YearStr  := GetYearString;
  MonthStr := Format('%.2d', [FDate.Month]);
  DayStr   := Format('%.2d', [FDate.Day]);
  SepStr   := GetSeparatorChar;

  WYear  := Canvas.TextWidth(YearStr);
  WMonth := Canvas.TextWidth(MonthStr);
  WDay   := Canvas.TextWidth(DayStr);
  WSep   := Canvas.TextWidth(SepStr);

  CurX := RText.Left;
  case APart of
    dspYear:
      Result := Rect(CurX, RText.Top, CurX + WYear, RText.Bottom);
    dspMonth:
      begin
        CurX := CurX + WYear + WSep;
        Result := Rect(CurX, RText.Top, CurX + WMonth, RText.Bottom);
      end;
    dspDay:
      begin
        CurX := CurX + WYear + WSep + WMonth + WSep;
        Result := Rect(CurX, RText.Top, CurX + WDay, RText.Bottom);
      end;
  end;
end;

procedure TJalaliDatePicker.Loaded;
begin
  inherited Loaded;
  if FIsEmpty and FUseTodayIfEmpty then
  begin
    FDate := TJalaliCalendar.Today;
    FIsEmpty := False;
  end;
  SyncTextBuffer;
  Invalidate;
end;

procedure TJalaliDatePicker.SetUseTodayIfEmpty(Value: Boolean);
begin
  if FUseTodayIfEmpty <> Value then
  begin
    FUseTodayIfEmpty := Value;

    if FIsEmpty and FUseTodayIfEmpty then
    begin
      FDate := TJalaliCalendar.Today;
      FIsEmpty := False;
    end;
    SyncTextBuffer;
    Invalidate;
  end;
end;

procedure TJalaliDatePicker.SyncTextBuffer;
begin
  if FIsEmpty then
    FTextBuffer := ''
  else
    FTextBuffer := JalaliToDisplayText(FDate, FDateFormat);
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
  Sep: Char;
begin
  Result := False;
  ADate := FDate;

  if FDateFormat = jdfYYYYMMDD_Dash then Sep := '-' else Sep := '/';

  if Length(S) < 8 then Exit;

  Parts := S.Split([Sep]);
  if Length(Parts) <> 3 then Exit;

  if TryStrToInt(Parts[0], Y) and TryStrToInt(Parts[1], M) and TryStrToInt(Parts[2], D) then
  begin
    if Y < 100 then Inc(Y, 1400);
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
begin
  if (FDataLink.Field <> nil) and not (FDataLink.Field.IsNull) then
  begin
    FIsEmpty := False;
    if FDataLink.Field.DataType in [ftDate, ftDateTime] then
      SetDateTime(FDataLink.Field.AsDateTime)
    else
      SetValue(FDataLink.Field.AsString);
  end
  else
  begin
    if FUseTodayIfEmpty then
    begin
      FIsEmpty := False;
      FDate := TJalaliCalendar.Today;
    end
    else
      FIsEmpty := True;
  end;
  SyncTextBuffer;
  Invalidate;
end;

procedure TJalaliDatePicker.UpdateData(Sender: TObject);
begin
  if (FDataLink.Field <> nil) and (FDataLink.CanModify) then
  begin
    if FIsEmpty then
      FDataLink.Field.Clear
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
    Result := JalaliToDisplayText(FDate, FDateFormat);
end;

procedure TJalaliDatePicker.SetValue(const NewValue: string);
var
  ParsedDate: TJalaliDate;
  TrimmedValue: string;
  KeepFocus: Boolean;
begin
  TrimmedValue := Trim(NewValue);

  if TrimmedValue = '' then
  begin
    ClearDate;
    Exit;
  end;

  if IsValidJalaliStr(TrimmedValue, ParsedDate) then
  begin
    FIsEmpty := False;
    SetDate(ParsedDate);
  end
  else
  begin
    if FValidationErrorDisplay and Assigned(FOnValidationError) then
    begin
      KeepFocus := True;
      FOnValidationError(Self, TrimmedValue, KeepFocus);
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
    ClearDate
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

procedure TJalaliDatePicker.DrawDefaultCalendarIcon(const R: TRect);
var
  CX, CY, W, H: Integer;
  BoxR: TRect;
begin
  W := 14;
  H := 14;
  CX := R.Left + (R.Width - W) div 2;
  CY := R.Top + (R.Height - H) div 2;

  BoxR := Rect(CX, CY, CX + W, CY + H);

  Canvas.Pen.Color := $005A5A5A;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Color := clWhite;
  Canvas.Brush.Style := bsSolid;
  Canvas.Rectangle(BoxR);

  Canvas.Brush.Color := $00C0504D;
  Canvas.FillRect(Rect(BoxR.Left, BoxR.Top, BoxR.Right, BoxR.Top + 4));

  Canvas.Pen.Color := $00333333;
  Canvas.MoveTo(BoxR.Left + 3, BoxR.Top - 1);
  Canvas.LineTo(BoxR.Left + 3, BoxR.Top + 2);

  Canvas.MoveTo(BoxR.Right - 4, BoxR.Top - 1);
  Canvas.LineTo(BoxR.Right - 4, BoxR.Top + 2);

  Canvas.Brush.Color := $00787878;
  Canvas.FillRect(Rect(BoxR.Left + 3, BoxR.Top + 6, BoxR.Left + 5, BoxR.Top + 8));
  Canvas.FillRect(Rect(BoxR.Left + 6, BoxR.Top + 6, BoxR.Left + 8, BoxR.Top + 8));
  Canvas.FillRect(Rect(BoxR.Left + 9, BoxR.Top + 6, BoxR.Left + 11, BoxR.Top + 8));

  Canvas.FillRect(Rect(BoxR.Left + 3, BoxR.Top + 10, BoxR.Left + 5, BoxR.Top + 12));
  Canvas.FillRect(Rect(BoxR.Left + 6, BoxR.Top + 10, BoxR.Left + 8, BoxR.Top + 12));
  Canvas.FillRect(Rect(BoxR.Left + 9, BoxR.Top + 10, BoxR.Left + 11, BoxR.Top + 12));
end;

procedure TJalaliDatePicker.DrawCalendarIcon(const R: TRect);
var
  ImgX, ImgY: Integer;
begin
  if Assigned(FImages) and (FImageIndex >= 0) and (FImageIndex < FImages.Count) then
  begin
    ImgX := R.Left + (R.Width - FImages.Width) div 2;
    ImgY := R.Top + (R.Height - FImages.Height) div 2;
    FImages.Draw(Canvas, ImgX, ImgY, FImageIndex, Enabled);
  end
  else if (FDropIcon.Graphic <> nil) and (not FDropIcon.Graphic.Empty) then
  begin
    ImgX := R.Left + (R.Width - FDropIcon.Width) div 2;
    ImgY := R.Top + (R.Height - FDropIcon.Height) div 2;
    Canvas.Draw(ImgX, ImgY, FDropIcon.Graphic);
  end
  else
  begin
    DrawDefaultCalendarIcon(R);
  end;
end;

procedure TJalaliDatePicker.Paint;
var
  R, RText: TRect;
  YearStr, MonthStr, DayStr, SepStr: string;
  WYear, WMonth, WDay, WSep: Integer;
  BtnW, CurX: Integer;

  procedure DrawSegment(const AText: string; AWidth: Integer; IsSelected: Boolean);
  var
    SegR: TRect;
    Flags: UINT;
  begin
    SegR := Rect(CurX, RText.Top, CurX + AWidth, RText.Bottom);

    Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX;
    if UseRightToLeftAlignment then
      Flags := Flags or DT_RTLREADING;

    if IsSelected and Focused and Enabled and not FIsEmpty then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := clHighlight;
      Canvas.FillRect(SegR);

      Canvas.Font.Color := clHighlightText;
      Canvas.Brush.Style := bsClear;
      Winapi.Windows.DrawText(Canvas.Handle, PChar(AText), Length(AText), SegR, Flags);

      Canvas.Font.Assign(Self.Font);
      if not Enabled then Canvas.Font.Color := clGrayText;
    end
    else
    begin
      Canvas.Brush.Style := bsClear;
      Winapi.Windows.DrawText(Canvas.Handle, PChar(AText), Length(AText), SegR, Flags);
    end;

    Inc(CurX, AWidth);
  end;

begin
  inherited;
  Canvas.Brush.Color := Color;
  if not Enabled then Canvas.Brush.Color := clBtnFace;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  // اصلاح: استفاده از FBorderColor به جای رنگ ثابت
  Canvas.Pen.Color := FBorderColor;
  Canvas.Rectangle(0, 0, Width, Height);

  BtnW := GetDropButtonWidth;
  R := DropButtonRect;
  RText := TextRect;

  Canvas.Brush.Color := $00F3F3F3;
  Canvas.FillRect(Rect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1));

  // اصلاح: خط جداکننده دکمه نیز از BorderColor استفاده می‌کند
  Canvas.Pen.Color := FBorderColor;
  Canvas.MoveTo(R.Right, R.Top);
  Canvas.LineTo(R.Right, R.Bottom);

  DrawCalendarIcon(R);

  Canvas.Font.Assign(Self.Font);
  if not Enabled then Canvas.Font.Color := clGrayText;

  if not FIsEmpty then
  begin
    YearStr  := GetYearString;
    MonthStr := Format('%.2d', [FDate.Month]);
    DayStr   := Format('%.2d', [FDate.Day]);
    SepStr   := GetSeparatorChar;

    WYear  := Canvas.TextWidth(YearStr);
    WMonth := Canvas.TextWidth(MonthStr);
    WDay   := Canvas.TextWidth(DayStr);
    WSep   := Canvas.TextWidth(SepStr);

    CurX := RText.Left;

    DrawSegment(YearStr, WYear, FSelectedPart = dspYear);
    DrawSegment(SepStr, WSep, False);
    DrawSegment(MonthStr, WMonth, FSelectedPart = dspMonth);
    DrawSegment(SepStr, WSep, False);
    DrawSegment(DayStr, WDay, FSelectedPart = dspDay);
  end;

  if Focused then
  begin
    R := ClientRect;
    InflateRect(R, -2, -2);
    Canvas.Pen.Color := clHighlight;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(R);
  end;
end;

procedure TJalaliDatePicker.SelectPartAt(X: Integer);
var
  RYear, RMonth, RDay: TRect;
begin
  if FIsEmpty then Exit;

  RYear := GetPartRect(dspYear);
  RMonth := GetPartRect(dspMonth);
  RDay := GetPartRect(dspDay);

  if (X >= RYear.Left) and (X <= RYear.Right) then
    SetSelectedPart(dspYear)
  else if (X >= RMonth.Left) and (X <= RMonth.Right) then
    SetSelectedPart(dspMonth)
  else if (X >= RDay.Left) and (X <= RDay.Right) then
    SetSelectedPart(dspDay);
end;

procedure TJalaliDatePicker.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DropR: TRect;
begin
  inherited;
  if Button = mbLeft then
  begin
    if CanFocus then SetFocus;

    DropR := DropButtonRect;

    if PtInRect(DropR, Point(X, Y)) then
    begin
      ToggleDropDown;
    end
    else
    begin
      if Assigned(FDropDown) and FDropDown.Visible then
        CloseDropDown;

      SelectPartAt(X);
    end;
  end;
end;

procedure TJalaliDatePicker.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTCHARS or DLGC_WANTARROWS or DLGC_WANTALLKEYS;
end;

procedure TJalaliDatePicker.AdjustPartValue(Delta: Integer);
var
  Y, M, D, MaxD: Integer;
  NewDate: TJalaliDate;
begin
  if FIsEmpty then
  begin
    FDate := TJalaliCalendar.Today;
    FIsEmpty := False;
  end;

  Y := FDate.Year;
  M := FDate.Month;
  D := FDate.Day;

  case FSelectedPart of
    dspYear:  Inc(Y, Delta);
    dspMonth:
      begin
        Inc(M, Delta);
        if M > 12 then M := 1
        else if M < 1 then M := 12;
      end;
    dspDay:
      begin
        MaxD := TJalaliCalendar.DaysInMonth(Y, M);
        Inc(D, Delta);
        if D > MaxD then D := 1
        else if D < 1 then D := MaxD;
      end;
  end;

  MaxD := TJalaliCalendar.DaysInMonth(Y, M);
  if D > MaxD then D := MaxD;

  if not FDataLink.Editing then FDataLink.Edit;

  NewDate.Year := Y;
  NewDate.Month := M;
  NewDate.Day := D;
  SetDate(NewDate);
end;

procedure TJalaliDatePicker.ProcessCharInput(Ch: Char);
var
  Val, MaxLen, Y, M, D, MaxD: Integer;
  NewDate: TJalaliDate;
begin
  if not CharInSet(Ch, ['0'..'9']) then Exit;

  if FIsEmpty then
  begin
    FDate := TJalaliCalendar.Today;
    FIsEmpty := False;
  end;

  case FSelectedPart of
    dspYear:
      if FDateFormat = jdfYYMMDD then MaxLen := 2 else MaxLen := 4;
    dspMonth, dspDay: MaxLen := 2;
  end;

  FInputBuffer := FInputBuffer + Ch;
  Val := StrToIntDef(FInputBuffer, 0);

  Y := FDate.Year;
  M := FDate.Month;
  D := FDate.Day;

  case FSelectedPart of
    dspYear:
      begin
        if FDateFormat = jdfYYMMDD then
          Y := 1400 + Val
        else
          Y := Val;
      end;
    dspMonth: if (Val >= 1) and (Val <= 12) then M := Val;
    dspDay:
      begin
        MaxD := TJalaliCalendar.DaysInMonth(Y, M);
        if (Val >= 1) and (Val <= MaxD) then D := Val;
      end;
  end;

  if not FDataLink.Editing then FDataLink.Edit;

  NewDate.Year := Y;
  NewDate.Month := M;
  NewDate.Day := D;
  SetDate(NewDate);

  if Length(FInputBuffer) >= MaxLen then
  begin
    FInputBuffer := '';
    if FSelectedPart = dspYear then SetSelectedPart(dspMonth)
    else if FSelectedPart = dspMonth then SetSelectedPart(dspDay);
  end;
end;

procedure TJalaliDatePicker.ValidateAndApplyInput;
var
  Y, M, D, MaxD: Integer;
  NewDate: TJalaliDate;
begin
  if FInputBuffer = '' then Exit;

  case FSelectedPart of
    dspYear:
      begin
        if FDateFormat = jdfYYMMDD then
          Y := 1400 + StrToIntDef(FInputBuffer, FDate.Year mod 100)
        else
          Y := StrToIntDef(FInputBuffer, FDate.Year);
        M := FDate.Month;
        D := FDate.Day;
      end;
    dspMonth:
      begin
        Y := FDate.Year;
        M := StrToIntDef(FInputBuffer, FDate.Month);
        if M < 1 then M := 1 else if M > 12 then M := 12;
        D := FDate.Day;
      end;
    dspDay:
      begin
        Y := FDate.Year;
        M := FDate.Month;
        D := StrToIntDef(FInputBuffer, FDate.Day);
        MaxD := TJalaliCalendar.DaysInMonth(Y, M);
        if D < 1 then D := 1 else if D > MaxD then D := MaxD;
      end;
  else
    Exit;
  end;

  MaxD := TJalaliCalendar.DaysInMonth(Y, M);
  if D > MaxD then D := MaxD;

  NewDate.Year := Y;
  NewDate.Month := M;
  NewDate.Day := D;
  SetDate(NewDate);
  FInputBuffer := '';
end;

procedure TJalaliDatePicker.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);

  if Key = #8 then
  begin
    FInputBuffer := '';
    case FSelectedPart of
      dspDay: SetSelectedPart(dspMonth);
      dspMonth: SetSelectedPart(dspYear);
      dspYear:
        begin
          if not FIsEmpty then
          begin
            FIsEmpty := True;
            FTextBuffer := '';
            Invalidate;
            if Assigned(FOnChange) then FOnChange(Self, FDate);
          end;
        end;
    end;
    Key := #0;
    Exit;
  end;

  if Key >= #32 then
  begin
    ProcessCharInput(Key);
    Key := #0;
  end;
end;

procedure TJalaliDatePicker.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    ToggleDropDown;
    Key := 0;
    Exit;
  end;

  if Key = VK_UP then
  begin
    AdjustPartValue(1);
    Key := 0;
    Exit;
  end;

  if Key = VK_DOWN then
  begin
    AdjustPartValue(-1);
    Key := 0;
    Exit;
  end;

  if Key = VK_LEFT then
  begin
    ValidateAndApplyInput;
    if FSelectedPart = dspDay then SetSelectedPart(dspMonth)
    else if FSelectedPart = dspMonth then SetSelectedPart(dspYear);
    Key := 0;
    Exit;
  end;

  if Key = VK_RIGHT then
  begin
    ValidateAndApplyInput;
    if FSelectedPart = dspYear then SetSelectedPart(dspMonth)
    else if FSelectedPart = dspMonth then SetSelectedPart(dspDay);
    Key := 0;
    Exit;
  end;

  if (Key = VK_TAB) then
    ValidateAndApplyInput;

  inherited KeyDown(Key, Shift);
end;

function TJalaliDatePicker.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if not Result then
  begin
    if WheelDelta > 0 then
      AdjustPartValue(1)
    else
      AdjustPartValue(-1);
    Result := True;
  end;
end;

procedure TJalaliDatePicker.DoEnter;
begin
  inherited DoEnter;
  SyncTextBuffer;
  FSelectedPart := dspYear;
  FInputBuffer := '';
  Invalidate;
end;

procedure TJalaliDatePicker.DoExit;
begin
  ValidateAndApplyInput;
  FInputBuffer := '';
  inherited DoExit;
  Invalidate;
end;

procedure TJalaliDatePicker.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TJalaliDatePicker.HookOwnerForm;
var
  Form: TCustomForm;
begin
  Form := GetParentForm(Self);
  if Assigned(Form) and Form.HandleAllocated then
  begin
    SetWindowSubclass(Form.Handle, @OwnerFormSubclassProc, UINT_PTR(Self), DWORD_PTR(Self));
  end;
end;

procedure TJalaliDatePicker.UnhookOwnerForm;
var
  Form: TCustomForm;
begin
  Form := GetParentForm(Self);
  if Assigned(Form) and Form.HandleAllocated then
  begin
    RemoveWindowSubclass(Form.Handle, @OwnerFormSubclassProc, UINT_PTR(Self));
  end;
end;

procedure TJalaliDatePicker.ToggleDropDown;
var
  P: TPoint;
  Offset, TargetIndex: Integer;
  Mon: TMonitor;
begin
  if Assigned(FDropDown) and FDropDown.Visible then
  begin
    CloseDropDown;
    Exit;
  end;

  if not Assigned(FDropDown) then
  begin
    FDropDown := TJalaliDropDownForm.CreateNew(Self);
    FDropDown.Picker := Self;
    FDropDown.PopupMode := pmExplicit;
    FDropDown.PopupParent := GetParentForm(Self);
    FDropDown.Calendar.OnSelectDate := PopupDateSelected;
  end;

  FDropDown.Calendar.Font.Assign(Self.Font);

  if FIsEmpty then
    FDropDown.Calendar.SelectedDate := TJalaliCalendar.Today
  else
    FDropDown.Calendar.SelectedDate := FDate;

  FDropDown.Calendar.AdjustDimensions;

  if FDropDownWidth > 0 then
    FDropDown.Width := FDropDownWidth;

  Offset := FDropDown.Calendar.FirstDayOffset_Sat0;
  if FIsEmpty then
    TargetIndex := (TJalaliCalendar.Today.Day - 1) + Offset
  else
    TargetIndex := (FDate.Day - 1) + Offset;

  FDropDown.Calendar.HoverIndex := TargetIndex;

  P := ClientToScreen(Point(0, Height));

  Mon := Screen.MonitorFromWindow(Handle);
  if P.X + FDropDown.Width > Mon.Left + Mon.Width then
    P.X := Mon.Left + Mon.Width - FDropDown.Width;
  if P.X < Mon.Left then
    P.X := Mon.Left;
  if P.Y + FDropDown.Height > Mon.Top + Mon.Height then
    P.Y := ClientToScreen(Point(0, 0)).Y - FDropDown.Height;

  FDropDown.SetBounds(P.X, P.Y, FDropDown.Width, FDropDown.Height);

  HookedPicker := Self;
  MouseHookHandle := SetWindowsHookEx(WH_MOUSE, @DatePickerMouseHook, 0, GetCurrentThreadId);

  HookOwnerForm;

  Winapi.Windows.SetWindowPos(FDropDown.Handle, HWND_TOPMOST, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW);
  FDropDown.Visible := True;
end;

procedure TJalaliDatePicker.CloseDropDown;
begin
  if MouseHookHandle <> 0 then
  begin
    UnhookWindowsHookEx(MouseHookHandle);
    MouseHookHandle := 0;
  end;
  HookedPicker := nil;

  if Assigned(FDropDown) then
    FDropDown.Visible := False;
  UnhookOwnerForm;
end;

procedure TJalaliDatePicker.PopupDateSelected(Sender: TObject; const ADate: TJalaliDate);
begin
  if FDataLink.Editing or FDataLink.Edit then
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
  if CanFocus then SetFocus;
end;

end.
