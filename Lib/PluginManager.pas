unit PluginManager;

interface

uses
  Windows, SysUtils, Classes,
  PluginAPI;

type
  EPluginManagerError = class(Exception);
    EPluginLoadError = class(EPluginManagerError);
      EPluginsLoadError = class(EPluginLoadError)
      private
        FItems: TStrings;
      public
        constructor Create(const AText: String; const AFailedPlugins: TStrings);
        destructor Destroy; override;
        property FailedPluginFileNames: TStrings read FItems;
      end;

  IPlugin = interface
  // protected
    function GetIndex: Integer;
    function GetHandle: HMODULE;
    function GetFileName: String;

    function GetTaskCount: Integer;
    function GetTaskName(Index: Integer): WideString;
    function GetTaskDescription(Index: Integer): WideString;
    function GetTaskParameter(Index: Integer): WideString;
    function GetTaskFunction(Index: Integer): TTaskFunc;
  // public
    property Index: Integer read GetIndex;
    property Handle: HMODULE read GetHandle;
    property FileName: String read GetFileName;

    property TaskCount: Integer read GetTaskCount;
    property TaskName[Index: Integer]: WideString read GetTaskName;
    property TaskDescr[Index: Integer]: WideString read GetTaskDescription;
    property TaskParam[Index: Integer]: WideString read GetTaskParameter;
    property TaskFunc[Index: Integer]: TTaskFunc read GetTaskFunction;
  end;

  IPluginManager = interface
  // protected
    function GetItem(const AIndex: Integer): IPlugin;
    function GetCount: Integer;
  // public
    function LoadPlugin(const AFileName: String): IPlugin;
    procedure UnloadPlugin(const AIndex: Integer);

    procedure LoadPlugins(const AFolder: String; const AFileExt: String = '.dll');

    property Items[const AIndex: Integer]: IPlugin read GetItem; default;
    property Count: Integer read GetCount;

    procedure UnloadAll;
  end;

function Plugins: IPluginManager;

implementation

uses
  Registry;

resourcestring
  rsPluginsLoadError = 'One or more plugins has failed to load:' + sLineBreak + '%s';

type
  TPluginManager = class(TInterfacedObject, IUnknown, IPluginManager, ICoreInfo)
  private
    FItems: array of IPlugin;
    FCount: Integer;
    FVersion: Integer;
  protected
    function GetItem(const AIndex: Integer): IPlugin;
    function GetCount: Integer;
    function CanLoad(const AFileName: String): Boolean;
    function Get_Version: Integer; safecall;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadPlugin(const AFileName: String): IPlugin;
    procedure UnloadPlugin(const AIndex: Integer);
    procedure LoadPlugins(const AFolder, AFileExt: String);
    function IndexOf(const APlugin: IPlugin): Integer;
    procedure UnloadAll;
  end;

  TPlugin = class(TInterfacedObject, IPlugin)
  private
    FManager: TPluginManager;
    FFileName: String;
    FHandle: HMODULE;

    FInit: TInitPluginFunc;
    FDone: TDonePluginFunc;

    FPlugin: IInterface;
    FInfoLoaded: Boolean;
    FID: TGUID;
    FTaskCount: Integer;
    FTaskName: array of WideString;
    FTaskDescription: array of WideString;
    FTaskParameter: array of WideString;
    procedure GetInfo;
  protected
    function GetIndex: Integer;
    function GetHandle: HMODULE;
    function GetFileName: String;

    function GetID: TGUID;
    function GetTaskCount: Integer;
    function GetTaskName(Index: Integer): WideString;
    function GetTaskDescription(Index: Integer): WideString;
    function GetTaskParameter(Index: Integer): WideString;
    function GetTaskFunction(Index: Integer): TTaskFunc;
  public
    constructor Create(const APluginManger: TPluginManager; const AFileName: String); virtual;
    destructor Destroy; override;
  end;

{ TPluginManager }

constructor TPluginManager.Create;
begin
  inherited Create;
  FVersion := 3;
end;

destructor TPluginManager.Destroy;
begin
  inherited;
end;

function TPluginManager.LoadPlugin(const AFileName: String): IPlugin;
begin
  if not CanLoad(AFileName) then
  begin
    Result := nil;
    Exit;
  end;

  // Загружаем плагин
  try
    Result := TPlugin.Create(Self, AFileName);
  except
    on E: Exception do
      raise EPluginLoadError.Create(Format('[%s] %s', [E.ClassName, E.Message]));
  end;

  // Заносим в список
  if Length(FItems) >= FCount then // "Capacity"
    SetLength(FItems, Length(FItems) + 64);
  FItems[FCount] := Result;
  Inc(FCount);
end;

procedure TPluginManager.LoadPlugins(const AFolder, AFileExt: String);

  function PluginOK(const APluginName, AFileExt: String): Boolean;
  begin
    Result := (AFileExt = '');
    if Result then
      Exit;
    Result := SameFileName(ExtractFileExt(APluginName), AFileExt);
  end;

var
  Path: String;
  SR: TSearchRec;
  Failures: TStringList;
  FailedPlugins: TStringList;
begin
  Path := IncludeTrailingPathDelimiter(AFolder);

  Failures := TStringList.Create;
  FailedPlugins := TStringList.Create;
  try
    if FindFirst(Path + '*.*', 0, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) = 0) and
           PluginOK(SR.Name, AFileExt) then
        try
          LoadPlugin(Path + SR.Name);
        except
          on E: Exception do
          begin
            FailedPlugins.Add(SR.Name);
            Failures.Add(Format('%s: %s', [SR.Name, E.Message]));
          end;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;

    if Failures.Count > 0 then
      raise EPluginsLoadError.Create(Format(rsPluginsLoadError, [Failures.Text]), FailedPlugins);
  finally
    FreeAndNil(FailedPlugins);
    FreeAndNil(Failures);
  end;
end;

procedure TPluginManager.UnloadAll;
begin
  Finalize(FItems);
end;

procedure TPluginManager.UnloadPlugin(const AIndex: Integer);
var
  X: Integer;
begin
  // Выгрузить плагин
  FItems[AIndex] := nil;
  // Сдвинуть плагины в списке, чтобы закрыть "дырку"
  for X := AIndex to FCount - 1 do
    FItems[X] := FItems[X + 1];
  // Не забыть учесть последний
  FItems[FCount - 1] := nil;
  Dec(FCount);
end;

function TPluginManager.IndexOf(const APlugin: IPlugin): Integer;
var
  X: Integer;
begin
  Result := -1;
  for X := 0 to FCount - 1 do
    if FItems[X] = APlugin then
    begin
      Result := X;
      Break;
    end;
end;

function TPluginManager.CanLoad(const AFileName: String): Boolean;
var
  X: Integer;
  FHandle: HMODULE;
  FInit: TInitPluginFunc;
begin
  // Не грузить уже загруженные
  for X := 0 to FCount - 1 do
    if SameFileName(FItems[X].FileName, AFileName) then
    begin
      Result := False;
      Exit;
    end;

  // Не грузить чужих dll
  FHandle := SafeLoadLibrary(AFileName, SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  try
    Win32Check(FHandle <> 0);
  except
    if FHandle <> 0 then
    begin
      FreeLibrary(FHandle);
      FHandle := 0;
    end;

    Result := False;
    Exit;
  end;

//  FDone := GetProcAddress(FHandle, SPluginDoneFuncName);
  FInit := GetProcAddress(FHandle, SPluginInitFuncName);
  try
    Win32Check(Assigned(FInit));
  except
    if FHandle <> 0 then
    begin
      FreeLibrary(FHandle);
      FHandle := 0;
    end;

    Result := False;
    Exit;
  end;

  Result := True;
end;

const
  SRegDisabledPlugins = 'Disabled plugins';
  SRegPluginX         = 'Plugin%d';

function TPluginManager.GetCount: Integer;
begin
  Result := FCount;
end;

function TPluginManager.GetItem(const AIndex: Integer): IPlugin;
begin
  Result := FItems[AIndex];
end;

function TPluginManager.Get_Version: Integer;
begin
  Result := FVersion;
end;

{ TPlugin }

constructor TPlugin.Create(const APluginManger: TPluginManager;
  const AFileName: String);
begin
  inherited Create;
  FManager := APluginManger;
  FFileName := AFileName;
  FHandle := SafeLoadLibrary(AFileName, SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  Win32Check(FHandle <> 0);

  FDone := GetProcAddress(FHandle, SPluginDoneFuncName);
  FInit := GetProcAddress(FHandle, SPluginInitFuncName);
  Win32Check(Assigned(FInit));
  FPlugin := FInit(FManager);
end;

destructor TPlugin.Destroy;
begin
  FPlugin := nil;
  if Assigned(FDone) then
    FDone;
  if FHandle <> 0 then
  begin
    FreeLibrary(FHandle);
    FHandle := 0;
  end;
  inherited;
end;

function TPlugin.GetFileName: String;
begin
  Result := FFileName;
end;

function TPlugin.GetHandle: HMODULE;
begin
  Result := FHandle;
end;

function TPlugin.GetIndex: Integer;
begin
  Result := FManager.IndexOf(Self);
end;

procedure TPlugin.GetInfo;
var
  Info: ITaskModule;
  i: Integer;
begin
  if FInfoLoaded then
    Exit;
  if Supports(FPlugin, ITaskModule, Info) then
  begin
    FID := Info.ID;
    FTaskCount := Info.TaskCount;
    SetLength(FTaskName, FTaskCount);
    for i := Low(FTaskName) to High(FTaskName) do
      FTaskName[i] := Info.GetTaskName(i);
    SetLength(FTaskDescription, FTaskCount);
    for i := Low(FTaskDescription) to High(FTaskDescription) do
      FTaskDescription[i] := Info.GetTaskDescription(i);
    SetLength(FTaskParameter, FTaskCount);
    for i := Low(FTaskParameter) to High(FTaskParameter) do
      FTaskParameter[i] := Info.GetTaskParameter(i);
    FInfoLoaded := True;
  end;
end;

function TPlugin.GetID: TGUID;
begin
  GetInfo;
  Result := FID;
end;

function TPlugin.GetTaskCount: Integer;
begin
  GetInfo;
  Result := FTaskCount;
end;

function TPlugin.GetTaskName(Index: Integer): WideString;
begin
  GetInfo;
  Result := FTaskName[Index];
end;

function TPlugin.GetTaskDescription(Index: Integer): WideString;
begin
  GetInfo;
  Result := FTaskDescription[Index];
end;

function TPlugin.GetTaskParameter(Index: Integer): WideString;
begin
  GetInfo;
  Result := FTaskParameter[Index];
end;

function TPlugin.GetTaskFunction(Index: Integer): TTaskFunc;
var
  Info: ITaskModule;
begin
  Result := nil;
  if Supports(FPlugin, ITaskModule, Info) then
  begin
    Result := Info.GetTaskFunction(Index);
  end;
end;

{ EPluginsLoadError }

constructor EPluginsLoadError.Create(const AText: String;
  const AFailedPlugins: TStrings);
begin
  inherited Create(AText);
  FItems := TStringList.Create;
  FItems.Assign(AFailedPlugins);
end;

destructor EPluginsLoadError.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

//________________________________________________________________

var
  FPluginManager: IPluginManager;

function Plugins: IPluginManager;
begin
  Result := FPluginManager;
end;

initialization
  FPluginManager := TPluginManager.Create;
finalization
  if Assigned(FPluginManager) then
    FPluginManager.UnloadAll;
  FPluginManager := nil;
end.
