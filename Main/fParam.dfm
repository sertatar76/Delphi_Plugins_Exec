object ParamForm: TParamForm
  Left = 0
  Top = 0
  Caption = #1042#1074#1077#1076#1080#1090#1077' '#1087#1072#1088#1072#1084#1077#1090#1088#1099
  ClientHeight = 125
  ClientWidth = 594
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  DesignSize = (
    594
    125)
  TextHeight = 15
  object lParam: TLabel
    Left = 8
    Top = 16
    Width = 60
    Height = 15
    Caption = #1055#1086#1076#1089#1082#1072#1079#1082#1072':'
  end
  object Label2: TLabel
    Left = 8
    Top = 53
    Width = 67
    Height = 15
    Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099':'
  end
  object edParam: TEdit
    Left = 81
    Top = 50
    Width = 505
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = '*.*'
  end
  object btnOk: TButton
    Left = 414
    Top = 88
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1054#1082
    TabOrder = 1
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 511
    Top = 88
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 2
  end
end
