library Second;

uses
  SysUtils, ShellApi, Windows, Classes, StrUtils,
  PluginAPI in '..\Lib\PluginAPI.pas';

{$R *.res}

const
  SPluginID: TGUID = '{CA835E7C-72ED-45D8-A0A6-84E027D4E786}';
  cTaskCount = 1;
  cTaskName: array [0..Pred(cTaskCount)] of WideString = (
    'Task 3'
  );
  cTaskDescr: array [0..Pred(cTaskCount)] of WideString = (
    'Выполнения Shell-команды с отслеживанием процесса'
  );
  cTaskParam: array [0..Pred(cTaskCount)] of WideString = (
    'Например, CLI архивирования файлов/папки. "C:\Program Files\WinRAR\winrar.exe" a 1.rar "C:\Projects\1.txt"'
  );

type
  TPlugin = class(TInterfacedObject, IUnknown, ITaskModule)
  private
    FCore: ICoreInfo;
  protected
    function Get_ID: TGUID; safecall;
    function GetTaskCount: Integer; safecall;
    function GetTaskName(Index: Integer): WideString; safecall;
    function GetTaskDescription(Index: Integer): WideString; safecall;
    function GetTaskParameter(Index: Integer): WideString; safecall;
    function GetTaskFunction(Index: Integer): TTaskFunc; safecall;
  public
    constructor Create(const ACore: IInterface);
  end;

{ TPlugin }

constructor TPlugin.Create(const ACore: IInterface);
begin
  inherited Create;
  if not Supports(ACore, ICoreInfo, FCore) then
    Assert(False);
  Assert(FCore.Version >= 1);
end;

function TPlugin.Get_ID: TGUID;
begin
  Result := SPluginID;
end;

function TPlugin.GetTaskCount: Integer;
begin
  Result := cTaskCount;
end;

function TPlugin.GetTaskName(Index: Integer): WideString;
begin
  if (Index >= Low(cTaskName)) and (Index <= High(cTaskName)) then
    Result := cTaskName[Index]
  else
    Result := '';
end;

function TPlugin.GetTaskDescription(Index: Integer): WideString;
begin
  if (Index >= Low(cTaskDescr)) and (Index <= High(cTaskDescr)) then
    Result := cTaskDescr[Index]
  else
    Result := '';
end;

function TPlugin.GetTaskParameter(Index: Integer): WideString;
begin
  if (Index >= Low(cTaskParam)) and (Index <= High(cTaskParam)) then
    Result := cTaskParam[Index]
  else
    Result := '';
end;

function Task3(Param: WideString; TaskTerminate: TTaskTerminate): WideString; safecall;
var
  bTerminate: Boolean;

  function ShellExec(const FileName: string; const ParamName: string): string;
  const
    cTimer = 1000;
  var
    ExecInfo: TShellExecuteInfo;
  begin
    FillChar(ExecInfo, SizeOf(TShellExecuteInfo), 0);
      with ExecInfo do
      begin
      cbSize := SizeOf(TShellExecuteInfo);
      fMask := SEE_MASK_NOCLOSEPROCESS;
      Wnd := 0; // Handle;
      lpFile := PChar(FileName);
      if ParamName <> '' then
        lpParameters := PChar(ParamName);
      nShow := SW_HIDE;
    end;

    if ShellExecuteEx(@ExecInfo) and (ExecInfo.hProcess <> 0) then
    begin
      while (WaitForSingleObject(ExecInfo.hProcess, cTimer) = WAIT_TIMEOUT) do
      begin
  //    Application.ProcessMessages;
        if Assigned(TaskTerminate) then
        begin
          TaskTerminate(bTerminate);
          if bTerminate then
            Break;
        end;
      end;
      CloseHandle(ExecInfo.hProcess);

      Result := 'Успешно';
    end
    else
      Result := cError + 'Ошибка запуска';
  end;

var
  slParam: TStringList;
  Param0, Param1, sParam: string;
  i, ipos: Integer;
begin
  Result := '';
  bTerminate := False;

  slParam := TStringList.Create;
  try
    slParam.Delimiter := cDelimParam;
    slParam.DelimitedText := Param;
    Param0 := slParam[0];
//    Param1 := Copy(sParam, Length(Param0) + 1, Length(sParam) - Length(Param0));
//    Param1 := '';
//    for i := 1 to slParam.Count - 1 do
//      Param1 := Param1 + IfThen(Param1 <> '', ' ') + slParam[i];
    if slParam.Count > 1 then
    begin
      sParam := Param;
      ipos := Pos(slParam[1], sParam, Length(Param0));
      if ipos > 0 then
        Param1 := Copy(sParam, ipos, Length(sParam) - ipos)
      else
        Param1 := '';
    end
    else
      Param1 := '';

    Result := ShellExec(Param0, Param1);
    if bTerminate then
      Result := cErrorUser;
  finally
    slParam.Free;
  end;
end;

function TPlugin.GetTaskFunction(Index: Integer): TTaskFunc;
begin
  case Index of
    0: Result := Task3;
  else
    Result := nil;
  end;
end;

{ Init }

function Init(const ACore: IInterface): IInterface; safecall;
begin
  Result := TPlugin.Create(ACore);
end;

procedure Done; safecall;
begin
  // ничего не делает
end;

exports
  Init name SPluginInitFuncName,
  Done name SPluginDoneFuncName;

end.
