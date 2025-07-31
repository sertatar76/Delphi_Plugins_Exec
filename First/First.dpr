library First;

uses
  SysUtils, Classes,
  PluginAPI in '..\Lib\PluginAPI.pas';

{$R *.res}

const
  SPluginID: TGUID = '{D994C17A-4C62-4F6D-ADC7-D43ED7E54892}';
  cTaskCount = 2;
  cTaskName: array [0..Pred(cTaskCount)] of WideString = (
    'Task 1',
    'Task 2'
  );
  cTaskDescr: array [0..Pred(cTaskCount)] of WideString = (
    'Поиск списка файлов по маске и стартовой папке поиска',
    'Поиск вхождений последовательности символов в файле'
  );
  cTaskParam: array [0..Pred(cTaskCount)] of WideString = (
    'Папка начала поиска;Маска поиска. Разделитель ;. Пример: C:\Temp;*.txt',
    'Поиск вхождений последовательности символов (можно несколько) в файле. Разделитель ;. Пример: C:\Temp\temp.bin;libsec;binsec'
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

function Task1(Param: WideString; TaskTerminate: TTaskTerminate): WideString; safecall;
var
  bTerminate: Boolean;

  procedure SearchFiles(const Path: string; const FileMask: string; ResultList: TStringList);
  var
    SearchRec: TSearchRec;
    PathName: string;
  begin
    PathName := IncludeTrailingPathDelimiter(Path);
    if FindFirst(PathName + FileMask, faAnyFile, SearchRec) = 0 then
    try
      repeat
        if Assigned(TaskTerminate) then
        begin
          TaskTerminate(bTerminate);
          if bTerminate then
            exit;
        end;

        if (SearchRec.Attr and faDirectory) = 0 then
        begin
          // Файл найден, добавляем в список
          ResultList.Add(PathName + SearchRec.Name);
        end
        else if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          // Обнаружен подкаталог, рекурсивно ищем в нем
          SearchFiles(PathName + SearchRec.Name, FileMask, ResultList);
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;

    if FileMask <> '*.*' then
    begin
      if FindFirst(PathName + '*.*', faAnyFile, SearchRec) = 0 then
      try
        repeat
          if Assigned(TaskTerminate) then
          begin
            TaskTerminate(bTerminate);
            if bTerminate then
              exit;
          end;

          if (SearchRec.Attr = faDirectory) then
          begin
            if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
            begin
              // Обнаружен подкаталог, рекурсивно ищем в нем
              SearchFiles(PathName + SearchRec.Name, FileMask, ResultList);
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  end;

var
  slParam, slFile: TStringList;
begin
  Result := '';

  slParam := TStringList.Create;
  slFile := TStringList.Create;
  try
    slParam.Delimiter := cDelimParam;
    slParam.DelimitedText := Param;
    if slParam.Count <> 2 then
      Result := cError + 'Ошибка получения параметров'
    else
    begin
      slFile.Delimiter := cDelimResult;
      SearchFiles(slParam[0], slParam[1], slFile);
      if bTerminate then
        Result := cErrorUser
      else
        Result := slFile.DelimitedText;
    end;
  finally
    slFile.Free;
    slParam.Free;
  end;
end;

function Task2(Param: WideString; TaskTerminate: TTaskTerminate): WideString; safecall;
var
  bTerminate: Boolean;
  i: Integer;

  procedure FindCharInFile(const FileName: string; const SearchChar: array of string; ResultList: TStringList);
  const
    cBuff = 4096;
  var
    FileHandle: THandle;
    Buffer: array[0..cBuff - 1] of Byte;
    BytesRead: Integer;
    i, j: Integer;
    FilePos, iaddr: Int64;
    FirstChar, NextChar: array of Char;
    inext: array of Integer;
  begin
    SetLength(FirstChar, Length(SearchChar));
    SetLength(NextChar, Length(SearchChar));
    SetLength(inext, Length(SearchChar));
    for j := Low(SearchChar) to High(SearchChar) do
    begin
      FirstChar[j] := SearchChar[j][1];
      inext[j] := -1;
      NextChar[j] := SearchChar[j][1];
    end;
    FileHandle := FileOpen(FileName, fmOpenRead or fmShareDenyNone);
    if FileHandle <> INVALID_HANDLE_VALUE then
    try
      FilePos := 0;
      repeat
        if Assigned(TaskTerminate) then
        begin
          TaskTerminate(bTerminate);
          if bTerminate then
            exit;
        end;

        BytesRead := FileRead(FileHandle, Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
        begin
          for i := 0 to BytesRead - 1 do
          begin
            for j := Low(SearchChar) to High(SearchChar) do
            begin
              if ((inext[j] = -1) and (Char(Buffer[i]) = FirstChar[j])) then // Нашли 1й символ
              begin
                inext[j] := 2;
                NextChar[j] := SearchChar[j][inext[j]];
              end
              else if (inext[j] > -1) then
              begin
                if Char(Buffer[i]) <> NextChar[j] then
                  inext[j] := -1;

                if (inext[j] > -1) and (inext[j] = Length(SearchChar[j])) then // Нашли все символы
                begin
                  iaddr := FilePos + i - Length(SearchChar[j]) + 1;
                  if Length(SearchChar) = 1 then
                    ResultList.Add(IntToStr(iaddr) + '[' + IntToHex(iaddr) + ']')
                  else
                    ResultList.Add(IntToStr(iaddr) + '[' + IntToHex(iaddr) + '] - ' + SearchChar[j]);
                end
                else if (inext[j] > -1) then
                begin
                  Inc(inext[j]);
                  NextChar[j] := SearchChar[j][inext[j]];
                end;
              end;
            end;
          end;
          FilePos := FilePos + BytesRead;
        end;
      until (BytesRead = 0); // Читаем пока не конец файла
    finally
      FileClose(FileHandle);
    end;
  end;

var
  slParam, slFile: TStringList;
  aParam1: array of string;
begin
  Result := '';

  slParam := TStringList.Create;
  slFile := TStringList.Create;
  try
    slParam.Delimiter := cDelimParam;
    slParam.DelimitedText := Param;
    if slParam.Count < 2 then
      Result := cError + 'Ошибка получения параметров'
    else
    begin
      slFile.Delimiter := cDelimResult;
      SetLength(aParam1, slParam.Count - 1);
      for i := Low(aParam1) to High(aParam1) do
        aParam1[i] := slParam[i + 1];
      FindCharInFile(slParam[0], aParam1, slFile);
      if bTerminate then
        Result := cErrorUser
      else
        Result := slFile.DelimitedText;
    end;
  finally
    slFile.Free;
    slParam.Free;
  end;
end;

function TPlugin.GetTaskFunction(Index: Integer): TTaskFunc;
begin
  case Index of
    0: Result := Task1;
    1: Result := Task2;
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
