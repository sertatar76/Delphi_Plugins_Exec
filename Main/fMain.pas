unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  uTask, Vcl.ExtCtrls;

type
  TTaskList = record
    ind: integer;
    iPlugin: integer;
    iTask: integer;
  end;

  TMainForm = class(TForm)
    btnLoad: TButton;
    lbTasks: TListBox;
    FileOpenDialog1: TFileOpenDialog;
    lbCompletedTasks: TListBox;
    btnRun: TButton;
    mResult: TMemo;
    gbTask: TGroupBox;
    Panel1: TPanel;
    Panel2: TPanel;
    gbCompletedTasks: TGroupBox;
    Splitter1: TSplitter;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    gbRunnigTasks: TGroupBox;
    Panel3: TPanel;
    btnStop: TButton;
    lbRunnigTasks: TListBox;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    procedure btnLoadClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure lbCompletedTasksClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    aTaskList: array of TTaskList;
//    aTaskRunning: TList<TTask>;
    aTaskCompleted: array of TTask;

    procedure UpdatePluginsList;
    procedure UpdateTaskCompleted;
    procedure ShowResult(ind: Integer);
    procedure TaskBegin(Task: TTask);
    procedure TaskEnd(Task: TTask);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  PluginManager, PluginAPI, fParam;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
//  aTaskRunning := TList<TTask>.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
//  aTaskRunning.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  mResult.Lines.Clear;

  try
    Plugins.LoadPlugins(ExtractFileDir(ParamStr(0)));
  finally
    UpdatePluginsList;
  end;
end;

procedure TMainForm.UpdatePluginsList;
var
  i, j, l: Integer;
begin
  SetLength(aTaskList, 0);
  lbTasks.Items.BeginUpdate;
  try
    lbTasks.Items.Clear;
    for i := 0 to Plugins.Count - 1 do
    begin
      for j := 0 to Plugins[i].TaskCount - 1 do
      begin
        lbTasks.Items.Add(Format('%s: %s (%s)', [ExtractFileName(Plugins[i].FileName),
          Plugins[i].TaskName[j], Plugins[i].TaskDescr[j]]));

        l := Length(aTaskList);
        SetLength(aTaskList, l + 1);
        aTaskList[l].ind := l;
        aTaskList[l].iPlugin := i;
        aTaskList[l].iTask := j;
      end;
    end;
  finally
    lbTasks.Items.EndUpdate;
  end;
end;

procedure TMainForm.UpdateTaskCompleted;
var
  i: Integer;
  slResult: TStringList;
begin
  slResult := TStringList.Create;
  lbCompletedTasks.Items.BeginUpdate;
  try
    for i := lbCompletedTasks.Items.Count to High(aTaskCompleted) do
    begin
      if aTaskCompleted[i].ErrorVal = '' then
      begin
        slResult.Delimiter := cDelimResult;
        slResult.DelimitedText := aTaskCompleted[i].ResultVal;
        lbCompletedTasks.Items.Add(Format('Module: %s, Task: %s, Param: %s, Result: %d',
          [aTaskCompleted[i].PluginName, aTaskCompleted[i].TaskName, aTaskCompleted[i].ParamVal, slResult.Count]));
      end
      else
      begin
        lbCompletedTasks.Items.Add(Format('Module: %s, Task: %s, Param: %s, Error',
          [aTaskCompleted[i].PluginName, aTaskCompleted[i].TaskName, aTaskCompleted[i].ParamVal]));
      end;
    end;
  finally
    lbCompletedTasks.Items.EndUpdate;
    slResult.Free;
  end;
end;

procedure TMainForm.ShowResult(ind: Integer);
var
  slResult: TStringList;
  i: Integer;
begin
  if (ind < Low(aTaskCompleted)) or (ind > High(aTaskCompleted)) then
    Exit;

  slResult := TStringList.Create;
  try
    slResult.Delimiter := cDelimResult;
    slResult.DelimitedText := aTaskCompleted[ind].ResultVal;

    mResult.Lines.Clear;
    if aTaskCompleted[ind].ErrorVal = '' then
    begin
      for i := 0 to slResult.Count - 1 do
        mResult.Lines.Add(Format('%s', [slResult[i]]));
    end
    else
      mResult.Lines.Add(Format('%s', [aTaskCompleted[ind].ErrorVal]));
  finally
    slResult.Free;
  end;
end;

procedure TMainForm.lbCompletedTasksClick(Sender: TObject);
var
  ind: Integer;
begin
  ind := lbCompletedTasks.ItemIndex;
  if ind < 0 then
    Exit;

  ShowResult(ind);
end;

procedure TMainForm.btnLoadClick(Sender: TObject);
begin
  FileOpenDialog1.DefaultFolder := ExtractFileDir(ParamStr(0));
  if not FileOpenDialog1.Execute() then
    exit;

  try
    Plugins.LoadPlugin(FileOpenDialog1.FileName);
  finally
    UpdatePluginsList;
  end;
end;

procedure TMainForm.btnRunClick(Sender: TObject);
var
  ind: Integer;
  Task: TTask;
begin
  ind := lbTasks.ItemIndex;
  if (ind < Low(aTaskList)) or (ind > High(aTaskList)) then
  begin
    ShowMessage('Выберите задачу для запуска');
    Exit;
  end;

  Task := TTaskBuilder.Create
    .SetPluginName(ExtractFileName(Plugins[aTaskList[ind].iPlugin].FileName))
    .SetTaskName(Plugins[aTaskList[ind].iPlugin].TaskName[aTaskList[ind].iTask])
    .SetTaskFunc(Plugins[aTaskList[ind].iPlugin].TaskFunc[aTaskList[ind].iTask])
    .Build;

  if not Assigned(Task.TaskFunc) then
  begin
    ShowMessage('Ошибка запуска задачи');
    Exit;
  end;

  Application.CreateForm(TParamForm, ParamForm);
  try
    ParamForm.lParam.Caption := Plugins[aTaskList[ind].iPlugin].TaskParam[aTaskList[ind].iTask];
    if ParamForm.ShowModal = mrOk then
      Task.ParamVal := ParamForm.edParam.Text
    else
      exit;
  finally
    ParamForm.Free;
  end;

  try
    TaskBegin(Task);
    Task.Execute(TaskEnd);
  except
    on E: Exception do
      ShowMessage(Format('Ошибка выполнения задачи: %s', [E.Message]));
  end;
end;

procedure TMainForm.btnStopClick(Sender: TObject);
var
  ind: Integer;
  Task: TTask;
begin
  ind := lbRunnigTasks.ItemIndex;
//  if (ind < 0) or (ind > aTaskRunning.Count - 1) then
  if (ind < 0) then
  begin
    ShowMessage('Выберите задачу для остановки');
    Exit;
  end;

  try
    Task := lbRunnigTasks.Items.Objects[ind] as TTask;
  except
    ShowMessage('Ошибка получения объекта');
  end;
//  Task.TaskThread.Terminate;
//  Task.TaskThread.WaitFor;
  Task.Terminate := True;
end;

procedure TMainForm.TaskBegin(Task: TTask);
begin
  lbRunnigTasks.Items.AddObject(Format('Module: %s, Task: %s, Param: %s',
    [Task.PluginName, Task.TaskName, Task.ParamVal]), Task);
end;

procedure TMainForm.TaskEnd(Task: TTask);
var
  l, ind: Integer;
begin
  ind := lbRunnigTasks.Items.IndexOfObject(Task);
  if ind > -1 then
    lbRunnigTasks.Items.Delete(ind);

  l := Length(aTaskCompleted);
  SetLength(aTaskCompleted, l + 1);
  aTaskCompleted[l] := Task;
  UpdateTaskCompleted;
end;

end.
