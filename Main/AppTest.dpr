program AppTest;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {MainForm},
  PluginManager in '..\Lib\PluginManager.pas',
  PluginAPI in '..\Lib\PluginAPI.pas',
  fParam in 'fParam.pas' {ParamForm},
  uTask in 'uTask.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
