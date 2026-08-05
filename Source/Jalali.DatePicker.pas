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

  TJalaliValidationErrorEvent = procedure(Sender: TObject; const InvalidText: string; var KeepFocus: Boolean) of object;

  // تقویم پاپ‌آپ فقط یک تفاوت با پنل معمولی دارد: هنگام AdjustDimensions
  // اگر داخل یک فرم مستقل (TJalaliDropDownForm) باشد، اندازهٔ آن فرم را هم
  // با خودش هماهنگ می‌کند. بقیهٔ منطق (رسم/ماوس/کیبورد) در کلاس پایه است.
  TJalaliPopupCalendar = class(TJalaliCalendarCore)
  public
    procedure AdjustDimensions; override;
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

{ TJalaliPopupCalendar }

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
      FDropDown.Calendar.SelectedDate := ParsedDate;
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
      FDropDown.Calendar.DoKeyDown(Key, Shift);
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
    WM_MOVE, WM_SIZE:
      begin
        // به محض شروع جابجایی/تغییر اندازهٔ واقعیِ فرم، دراپ‌داون را می‌بندیم.
        // عمداً WM_WINDOWPOSCHANGING اینجا بررسی نمی‌شود، چون این پیام برای هر
        // تغییر ترتیب Z (مثلاً هنگام کلیک داخل خودِ دراپ‌داون) هم ارسال می‌شود
        // و باعث بسته شدن زودهنگام/کاذب دراپ‌داون قبل از ثبت کلیک می‌شد.
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
    FDropDown.Calendar.SelectedDate := TJalaliCalendar.Today
  else
    FDropDown.Calendar.SelectedDate := FDate;

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
