unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Jalali.DatePicker, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList, cxImageList, cxGraphics, Vcl.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin, Data.DB, Vcl.Grids, Vcl.DBGrids,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Imaging.pngimage,
  Vcl.WinXPickers,Jalali.Calendar;

type
  TForm1 = class(TForm)
    JalaliDatePicker1: TJalaliDatePicker;
    cxImageList1: TcxImageList;
    btnInc: TButton;
    tb_value: TEdit;
    JalaliDatePicker2: TJalaliDatePicker;
    Button1: TButton;
    Button2: TButton;
    procedure btnIncClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnIncClick(Sender: TObject);
begin
  JalaliDatePicker2.Date := JalaliDatePicker1.Date.IncMonth(StrToInt(tb_value.Text));
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  JalaliDatePicker2.Date := JalaliDatePicker1.Date.IncDay(StrToInt(tb_value.Text));
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  JalaliDatePicker2.Date := JalaliDatePicker1.Date.IncYear(StrToInt(tb_value.Text));
end;

end.
