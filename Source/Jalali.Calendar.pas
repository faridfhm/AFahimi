unit Jalali.Calendar;

interface

uses
  System.SysUtils, System.DateUtils;

type
  TJalaliDate = record
    Year: Integer;
    Month: Integer;
    Day: Integer;
    class function Create(AYear, AMonth, ADay: Integer): TJalaliDate; static;
    function IsValid: Boolean;
    function ToDisplayString: string;

    { متدهای جدید افزایشی و کاهشی }
    function IncDay(NumberOfDays: Integer = 1): TJalaliDate;
    function IncMonth(NumberOfMonths: Integer = 1): TJalaliDate;
    function IncYear(NumberOfYears: Integer = 1): TJalaliDate;
  end;

  TJalaliCalendar = class
  public
    class function IsLeapYear(JYear: Integer): Boolean; static;
    class function DaysInMonth(JYear, JMonth: Integer): Integer; static;
    class function IsValidDate(JYear, JMonth, JDay: Integer): Boolean; static;

    class function GregorianToJalali(Year, Month, Day: Integer): TJalaliDate; static;
    class function JalaliToGregorian(const JDate: TJalaliDate): TDateTime; static;

    class function DateTimeToJalali(const ADateTime: TDateTime): TJalaliDate; static;
    class function JalaliToDateTime(JYear, JMonth, JDay: Integer): TDateTime; static;

    class function Today: TJalaliDate; static;
  end;

implementation

const
  GDaysInMonth: array[1..12] of Integer =
    (31,28,31,30,31,30,31,31,30,31,30,31);

function FloorDiv(A, B: Integer): Integer;
var
  Q: Integer;
begin
  Q := A div B;
  if ((A mod B) <> 0) and ((A < 0) <> (B < 0)) then
    Dec(Q);
  Result := Q;
end;

function FloorMod(A, B: Integer): Integer;
begin
  Result := A - B * FloorDiv(A, B);
end;

function RawGregorianToJDN(Year, Month, Day: Integer): Integer;
var
  Gy, Gm, Gd: Integer;
  GDayNo: Integer;
  I: Integer;
  Leap: Boolean;
begin
  Gy := Year - 1600;
  Gm := Month - 1;
  Gd := Day - 1;

  GDayNo := 365 * Gy + FloorDiv(Gy + 3, 4) - FloorDiv(Gy + 99, 100) + FloorDiv(Gy + 399, 400);

  for I := 1 to Gm do
    Inc(GDayNo, GDaysInMonth[I]);

  Leap := ((Year mod 4 = 0) and (Year mod 100 <> 0)) or (Year mod 400 = 0);
  if (Gm > 1) and Leap then
    Inc(GDayNo);

  Inc(GDayNo, Gd);
  Result := GDayNo;
end;

function RawJDNToJalali(GDayNo: Integer): TJalaliDate;
var
  Jy, Jm, Jd: Integer;
  JDayNo: Integer;
begin
  JDayNo := GDayNo - 79;
  Jy := 979 + 33 * FloorDiv(JDayNo, 12053);
  JDayNo := FloorMod(JDayNo, 12053);

  Inc(Jy, 4 * FloorDiv(JDayNo, 1461));
  JDayNo := FloorMod(JDayNo, 1461);

  if JDayNo >= 366 then
  begin
    Inc(Jy, FloorDiv(JDayNo - 1, 365));
    JDayNo := FloorMod(JDayNo - 1, 365);
  end;

  if JDayNo < 186 then
  begin
    Jm := 1 + FloorDiv(JDayNo, 31);
    Jd := 1 + FloorMod(JDayNo, 31);
  end
  else
  begin
    Jm := 7 + FloorDiv(JDayNo - 186, 30);
    Jd := 1 + FloorMod(JDayNo - 186, 30);
  end;

  Result := TJalaliDate.Create(Jy, Jm, Jd);
end;

function RawJalaliToJDN(Jy0, Jm0, Jd0: Integer): Integer;
var
  Jy, Jm, Jd: Integer;
  JDayNo: Integer;
  I: Integer;
begin
  Jy := Jy0 - 979;
  Jm := Jm0 - 1;
  Jd := Jd0 - 1;

  JDayNo := 365 * Jy + FloorDiv(Jy, 33) * 8 + FloorDiv(FloorMod(Jy, 33) + 3, 4);

  for I := 0 to Jm - 1 do
  begin
    if I < 6 then
      Inc(JDayNo, 31)
    else
      Inc(JDayNo, 30);
  end;

  Inc(JDayNo, Jd);
  Result := JDayNo + 79;
end;

function RawJDNToGregorian(GDayNoIn: Integer): TDateTime;
var
  Gy, Gm, Gd: Integer;
  GDayNo: Integer;
  I: Integer;
  Leap: Boolean;
begin
  GDayNo := GDayNoIn;

  Gy := 1600 + 400 * FloorDiv(GDayNo, 146097);
  GDayNo := FloorMod(GDayNo, 146097);

  Leap := True;
  if GDayNo >= 36525 then
  begin
    Dec(GDayNo);
    Inc(Gy, 100 * FloorDiv(GDayNo, 36524));
    GDayNo := FloorMod(GDayNo, 36524);

    if GDayNo >= 365 then
      Inc(GDayNo)
    else
      Leap := False;
  end;

  Inc(Gy, 4 * FloorDiv(GDayNo, 1461));
  GDayNo := FloorMod(GDayNo, 1461);

  if GDayNo >= 366 then
  begin
    Leap := False;
    Dec(GDayNo);
    Inc(Gy, FloorDiv(GDayNo, 365));
    GDayNo := FloorMod(GDayNo, 365);
  end;

  Gm := 1;
  while True do
  begin
    I := GDaysInMonth[Gm];
    if (Gm = 2) and Leap then
      Inc(I);

    if GDayNo < I then
      Break;

    Dec(GDayNo, I);
    Inc(Gm);
  end;

  Gd := GDayNo + 1;
  Result := EncodeDate(Gy, Gm, Gd);
end;

{ ===== TJalaliDate ===== }

class function TJalaliDate.Create(AYear, AMonth, ADay: Integer): TJalaliDate;
begin
  Result.Year := AYear;
  Result.Month := AMonth;
  Result.Day := ADay;
end;

function TJalaliDate.IsValid: Boolean;
begin
  Result := TJalaliCalendar.IsValidDate(Year, Month, Day);
end;

function TJalaliDate.ToDisplayString: string;
begin
  Result := Format('%.4d/%.2d/%.2d', [Year, Month, Day]);
end;

function TJalaliDate.IncDay(NumberOfDays: Integer): TJalaliDate;
var
  DT: TDateTime;
begin
  // تبدیل به میلادی، افزودن روز (مقدار منفی برای کاهش) و تبدیل مجدد به جلالی
  DT := TJalaliCalendar.JalaliToGregorian(Self);
  DT := System.DateUtils.IncDay(DT, NumberOfDays);
  Result := TJalaliCalendar.DateTimeToJalali(DT);
end;

function TJalaliDate.IncMonth(NumberOfMonths: Integer): TJalaliDate;
var
  NewYear, NewMonth, NewDay: Integer;
  MaxDays: Integer;
begin
  // محاسبه ماه و سال جدید بدون در نظر گرفتن روز
  NewMonth := Month + NumberOfMonths - 1;
  NewYear := Year + FloorDiv(NewMonth, 12);
  NewMonth := FloorMod(NewMonth, 12) + 1;

  // بررسی اینکه روز فعلی در ماه جدید معتبر است یا خیر (کنترل انتهای ماه)
  MaxDays := TJalaliCalendar.DaysInMonth(NewYear, NewMonth);
  if Day > MaxDays then
    NewDay := MaxDays
  else
    NewDay := Day;

  Result := TJalaliDate.Create(NewYear, NewMonth, NewDay);
end;

function TJalaliDate.IncYear(NumberOfYears: Integer): TJalaliDate;
var
  NewYear, NewDay: Integer;
begin
  NewYear := Year + NumberOfYears;

  // مدیریت حالت خاص: اگر تاریخ ۳۰ اسفند در سال کبیسه باشد و سال جدید کبیسه نباشد، روز به ۲۹ تغییر می‌کند
  if (Month = 12) and (Day = 30) and (not TJalaliCalendar.IsLeapYear(NewYear)) then
    NewDay := 29
  else
    NewDay := Day;

  Result := TJalaliDate.Create(NewYear, Month, NewDay);
end;

{ ===== TJalaliCalendar ===== }

class function TJalaliCalendar.IsLeapYear(JYear: Integer): Boolean;
begin
  Result := (RawJalaliToJDN(JYear + 1, 1, 1) - RawJalaliToJDN(JYear, 1, 1)) = 366;
end;

class function TJalaliCalendar.DaysInMonth(JYear, JMonth: Integer): Integer;
begin
  case JMonth of
    1..6: Result := 31;
    7..11: Result := 30;
    12:
      if IsLeapYear(JYear) then
        Result := 30
      else
        Result := 29;
  else
    Result := 0;
  end;
end;

class function TJalaliCalendar.IsValidDate(JYear, JMonth, JDay: Integer): Boolean;
begin
  Result :=
    (JYear >= 1) and
    (JMonth >= 1) and (JMonth <= 12) and
    (JDay >= 1) and (JDay <= DaysInMonth(JYear, JMonth));
end;

class function TJalaliCalendar.GregorianToJalali(Year, Month, Day: Integer): TJalaliDate;
begin
  Result := RawJDNToJalali(RawGregorianToJDN(Year, Month, Day));
end;

class function TJalaliCalendar.JalaliToGregorian(const JDate: TJalaliDate): TDateTime;
begin
  if not JDate.IsValid then
    raise EConvertError.Create('Invalid Jalali date');

  Result := RawJDNToGregorian(RawJalaliToJDN(JDate.Year, JDate.Month, JDate.Day));
end;

class function TJalaliCalendar.DateTimeToJalali(const ADateTime: TDateTime): TJalaliDate;
var
  Y, M, D: Word;
begin
  DecodeDate(ADateTime, Y, M, D);
  Result := GregorianToJalali(Y, M, D);
end;

class function TJalaliCalendar.JalaliToDateTime(JYear, JMonth, JDay: Integer): TDateTime;
begin
  Result := JalaliToGregorian(TJalaliDate.Create(JYear, JMonth, JDay));
end;

class function TJalaliCalendar.Today: TJalaliDate;
begin
  Result := DateTimeToJalali(Date);
end;

end.
