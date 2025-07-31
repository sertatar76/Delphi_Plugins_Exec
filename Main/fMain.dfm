object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = #1054#1089#1085#1086#1074#1085#1086#1081' '#1084#1086#1076#1091#1083#1100
  ClientHeight = 520
  ClientWidth = 1110
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object Splitter3: TSplitter
    Left = 0
    Top = 313
    Width = 1110
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 100
    ExplicitWidth = 207
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1110
    Height = 313
    Align = alTop
    Caption = 'Panel1'
    TabOrder = 0
    object Splitter2: TSplitter
      Left = 577
      Top = 1
      Height = 311
      MinSize = 100
      ExplicitLeft = 16
      ExplicitTop = 104
      ExplicitHeight = 100
    end
    object gbTask: TGroupBox
      Left = 1
      Top = 1
      Width = 576
      Height = 311
      Align = alLeft
      Caption = #1047#1072#1075#1088#1091#1078#1077#1085#1085#1099#1077' '#1079#1072#1076#1072#1095#1080
      TabOrder = 0
      object lbTasks: TListBox
        Left = 2
        Top = 17
        Width = 572
        Height = 247
        Align = alClient
        ItemHeight = 15
        TabOrder = 0
      end
      object Panel2: TPanel
        Left = 2
        Top = 264
        Width = 572
        Height = 45
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 1
        object btnRun: TButton
          Left = 17
          Top = 9
          Width = 89
          Height = 25
          Hint = #1047#1072#1087#1091#1089#1090#1080#1090#1100' '#1079#1072#1076#1072#1095#1091
          Caption = #1047#1072#1087#1091#1089#1090#1080#1090#1100
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = btnRunClick
        end
        object btnLoad: TButton
          Left = 125
          Top = 9
          Width = 89
          Height = 25
          Hint = #1047#1072#1075#1088#1091#1079#1080#1090#1100' dll'
          Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = btnLoadClick
        end
      end
    end
    object gbRunnigTasks: TGroupBox
      Left = 580
      Top = 1
      Width = 529
      Height = 311
      Align = alClient
      Caption = #1042#1099#1087#1086#1083#1085#1103#1077#1084#1099#1077' '#1079#1072#1076#1072#1095#1080
      TabOrder = 1
      object Panel3: TPanel
        Left = 2
        Top = 264
        Width = 525
        Height = 45
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 0
        object btnStop: TButton
          Left = 17
          Top = 9
          Width = 89
          Height = 25
          Hint = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1079#1072#1076#1072#1095#1091
          Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = btnStopClick
        end
      end
      object lbRunnigTasks: TListBox
        Left = 2
        Top = 17
        Width = 525
        Height = 247
        Align = alClient
        ItemHeight = 15
        TabOrder = 1
      end
    end
  end
  object gbCompletedTasks: TGroupBox
    Left = 0
    Top = 316
    Width = 1110
    Height = 204
    Align = alClient
    Caption = #1042#1099#1087#1086#1083#1085#1077#1085#1099#1077' '#1079#1072#1076#1072#1095#1080
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 577
      Top = 17
      Height = 185
      MinSize = 100
      ExplicitLeft = 460
      ExplicitTop = 6
      ExplicitHeight = 188
    end
    object GroupBox1: TGroupBox
      Left = 2
      Top = 17
      Width = 575
      Height = 185
      Align = alLeft
      Caption = #1057#1087#1080#1089#1086#1082
      TabOrder = 0
      object lbCompletedTasks: TListBox
        Left = 2
        Top = 17
        Width = 571
        Height = 166
        Align = alClient
        ItemHeight = 15
        TabOrder = 0
        OnClick = lbCompletedTasksClick
      end
    end
    object GroupBox2: TGroupBox
      Left = 580
      Top = 17
      Width = 528
      Height = 185
      Align = alClient
      Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090#1099
      TabOrder = 1
      object mResult: TMemo
        Left = 2
        Top = 17
        Width = 524
        Height = 166
        Align = alClient
        Lines.Strings = (
          'Memo1')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 776
    Top = 88
  end
end
