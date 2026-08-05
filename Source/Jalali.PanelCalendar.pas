unit Jalali.PanelCalendar;

interface

uses
  System.Classes,
  Vcl.Graphics,
  Jalali.Calendar,
  Jalali.CalendarCore;

type
  // نمایش تقویم شمسی به‌صورت پنل ثابت (غیر پاپ‌آپ). تمام منطق رسم/ماوس/کیبورد
  // در کلاس پایهٔ مشترک TJalaliCalendarCore پیاده‌سازی شده؛ اینجا فقط
  // property های قابل‌طراحی (published) اضافه می‌شود.
  TJalaliPanelCalendar = class(TJalaliCalendarCore)
  public
    constructor Create(AOwner: TComponent); override;
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

    property BorderColor default $00CFCFCF;
    property HeaderBack default $00F3F3F3;
    property WeekBack default $00FBFBFB;
    property SelectBack default $00EEDDCB;
    property SelectPen default $00D0B090;

    property OnSelectDate;
  end;

//procedure Register;

implementation

{ TJalaliPanelCalendar }

constructor TJalaliPanelCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 210;
  Height := ComputeDefaultHeight;
end;

//procedure Register;
//begin
//  RegisterComponents('Jalali DatePicker', [TJalaliPanelCalendar]);
//end;

end.
