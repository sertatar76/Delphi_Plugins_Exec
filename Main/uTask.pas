unit uTask;

interface

uses
  Classes, PluginAPI;

type
  TTask = class;
  TThreadCallback = procedure(Result: string) of object;
  TTaskCallback = procedure(Task: TTask) of object;
  TTaskThread = class;

  TTask = class
  private
    FPluginName: string;
    FTaskName: string;
    FParamVal: string;
    FTaskFunc: TTaskFunc;
    FResultVal: string;
    FErrorVal: string;
    FTaskCallback: TTaskCallback;
    FTaskThread: TTaskThread;
    FTaskTerminate: TTaskTerminate;
    FTerminate: Boolean;
    procedure GetResult(Result: string);
  public
    property PluginName: string read FPluginName write FPluginName;
    property TaskName: string read FTaskName write FTaskName;
    property ParamVal: string read FParamVal write FParamVal;
    property TaskFunc: TTaskFunc read FTaskFunc write FTaskFunc;
    property ResultVal: string read FResultVal;
    property ErrorVal: string read FErrorVal;
    property TaskThread: TTaskThread read FTaskThread;
    property TaskTerminate: TTaskTerminate read FTaskTerminate write FTaskTerminate;
    property Terminate: Boolean read FTerminate write FTerminate;

    procedure Execute(const ATaskCallback: TTaskCallback);
    procedure GetTerminate(out bTerminate: Boolean); safecall;
  end;

  TTaskBuilder = class
  private
    FTask: TTask;
  public
    constructor Create;

    function SetPluginName(const Value: string): TTaskBuilder;
    function SetTaskName(const Value: string): TTaskBuilder;
    function SetTaskFunc(const Value: TTaskFunc): TTaskBuilder;
    function Build: TTask;
  end;

  TTaskThread = class(TThread)
  private
    FTask: TTask;
    FFuncResult: string;
    FCallback: TThreadCallback;
    procedure HandleTerminate;
   protected
    procedure Execute; override;
    procedure DoTerminate; override;
  public
    constructor Create(const ATask: TTask; const ACallback: TThreadCallback; CreateSuspended: Boolean);
  end;

implementation

{ TTaskBuilder }

constructor TTaskBuilder.Create;
begin
  inherited;
  FTask := TTask.Create;

  FTask.Terminate := False;
  FTask.FTaskTerminate := FTask.GetTerminate;
end;

function TTaskBuilder.SetPluginName(const Value: string): TTaskBuilder;
begin
  FTask.PluginName := Value;
  Result := Self;
end;

function TTaskBuilder.SetTaskName(const Value: string): TTaskBuilder;
begin
  FTask.TaskName := Value;
  Result := Self;
end;

function TTaskBuilder.SetTaskFunc(const Value: TTaskFunc): TTaskBuilder;
begin
  FTask.TaskFunc := Value;
  Result := Self;
end;

function TTaskBuilder.Build: TTask;
begin
  Result := FTask;
end;

{ TTask }

procedure TTask.Execute(const ATaskCallback: TTaskCallback);
begin
  FTaskCallback := ATaskCallback;
  FTaskThread := TTaskThread.Create(Self, GetResult, False);
  FTaskThread.Resume;
end;

procedure TTask.GetResult(Result: string);
begin
  if Copy(Result, 1, Length(cError)) = cError  then
    FErrorVal := Copy(Result, Length(cError) + 1, Length(Result) - Length(cError))
  else
    FResultVal := Result;

  if Assigned(FTaskCallback) then
    FTaskCallback(Self);
end;

procedure TTask.GetTerminate(out bTerminate: Boolean);
begin
  bTerminate := FTerminate;
end;

{ TTaskThread }

constructor TTaskThread.Create(const ATask: TTask; const ACallback: TThreadCallback; CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FTask := ATask;
  FCallback := ACallback;
  FreeOnTerminate := True;
end;

procedure TTaskThread.Execute;
begin
  FFuncResult := FTask.TaskFunc(FTask.ParamVal, FTask.TaskTerminate);
end;

procedure TTaskThread.DoTerminate;
begin
  Synchronize(HandleTerminate);
end;

procedure TTaskThread.HandleTerminate;
begin
  if Assigned(FCallback) then
    FCallback(FFuncResult);
end;

end.
