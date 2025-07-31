unit fParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.ImageList,
  Vcl.ImgList, Vcl.Buttons;

type
  TParamForm = class(TForm)
    lParam: TLabel;
    Label2: TLabel;
    edParam: TEdit;
    btnOk: TButton;
    btnCancel: TButton;
    procedure btnOkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ParamForm: TParamForm;

implementation

{$R *.dfm}

procedure TParamForm.btnOkClick(Sender: TObject);
begin
  if Trim(edParam.Text) = '' then
    ShowMessage('¬ведите параметры')
  else
    ModalResult := mrOk;
end;

procedure TParamForm.FormShow(Sender: TObject);
begin
  edParam.Text := '';
end;

end.
