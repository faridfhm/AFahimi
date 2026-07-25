unit Jalali.Vcl.Register;

interface

procedure Register;

implementation

uses
  System.Classes,
  Jalali.DatePicker,
  Jalali.PanelCalendar;

procedure Register;
begin
  RegisterComponents('Jalali DatePicker', [TJalaliDatePicker]);
  RegisterComponents('Jalali DatePicker', [TJalaliPanelCalendar]);
end;

end.

