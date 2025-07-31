unit PluginAPI;

interface

const
  cDelimParam = ';';
  cDelimResult = ';';
  cError = '[Error]';
  cErrorUser = cError + 'Прервано пользователем';

type
  TInitPluginFunc = function(const ACore: IInterface): IInterface; safecall;
  TDonePluginFunc = procedure; safecall;

  // Тип для указателя на функцию задачи.
  TTaskTerminate = procedure(out bTerminate: Boolean) of object; safecall;
  TTaskFunc = function(Param: WideString; TaskTerminate: TTaskTerminate): WideString; safecall;

  // Интерфейс для модуля задач.
  ITaskModule = interface(IInterface)
    ['{43A21C0D-5365-49DA-94FA-66E7DAE5A6CA}'] // Генерируйте уникальный GUID для каждого интерфейса!
    function Get_ID: TGUID; safecall;
    function GetTaskCount: Integer; safecall;
    function GetTaskName(Index: Integer): WideString; safecall;
    function GetTaskDescription(Index: Integer): WideString; safecall;
    function GetTaskParameter(Index: Integer): WideString; safecall;
    function GetTaskFunction(Index: Integer): TTaskFunc; safecall;

    property ID: TGUID read Get_ID;
    property TaskCount: Integer read GetTaskCount;
  end;

  ICoreInfo = interface(IUnknown)
    ['{3BAA3534-5422-42B9-BDEA-1CE1037295B3}']
    function Get_Version: Integer; safecall;
    property Version: Integer read Get_Version;
  end;

const
  SPluginInitFuncName = '5DA96ABEEC9049E48C94CCD2BA7DBE87';
  SPluginDoneFuncName = SPluginInitFuncName + '_done';

implementation

end.


