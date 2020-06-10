object DPMForm: TDPMForm
  Left = 0
  Top = 0
  Caption = 'Apollo DPM - Delphi Package Manager'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMainContainer: TPanel
    Left = 0
    Top = 0
    Width = 619
    Height = 441
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    Caption = 'pnlMainContainer'
    TabOrder = 0
    object splHorizontal: TSplitter
      Left = 0
      Top = 339
      Width = 619
      Height = 2
      Cursor = crVSplit
      Align = alBottom
    end
    object reActionLog: TRichEdit
      Left = 0
      Top = 341
      Width = 619
      Height = 100
      Align = alBottom
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      ParentFont = False
      ReadOnly = True
      TabOrder = 1
      Zoom = 100
      Font.Charset = RUSSIAN_CHARSET
    end
    object pnlMain: TPanel
      Left = 0
      Top = 0
      Width = 619
      Height = 339
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlMain'
      TabOrder = 0
      object splVertical: TSplitter
        Left = 170
        Top = 0
        Width = 2
        Height = 339
      end
      object tvNavigation: TTreeView
        Left = 0
        Top = 0
        Width = 170
        Height = 339
        Align = alLeft
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Indent = 19
        TabOrder = 0
      end
      object pnlPackages: TPanel
        Left = 172
        Top = 0
        Width = 447
        Height = 339
        Align = alClient
        BevelOuter = bvNone
        Caption = 'pnlPackages'
        TabOrder = 1
        object sbPackages: TScrollBox
          Left = 0
          Top = 30
          Width = 447
          Height = 309
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clWindow
          ParentColor = False
          TabOrder = 1
        end
        object pnlButtons: TPanel
          Left = 0
          Top = 0
          Width = 447
          Height = 30
          Align = alTop
          BevelOuter = bvNone
          Caption = 'pnlButtons'
          Color = clWindow
          ParentBackground = False
          ShowCaption = False
          TabOrder = 0
        end
      end
    end
  end
  object swPackageDetail: TSplitView
    Left = 609
    Top = 0
    Width = 15
    Height = 441
    CloseStyle = svcCompact
    Color = clWindow
    CompactWidth = 15
    Opened = False
    OpenedWidth = 200
    Placement = svpRight
    TabOrder = 1
    OnClosed = swPackageDetailClosed
    OnOpened = swPackageDetailOpened
    object pnlDetailSwitcher: TPanel
      Left = 0
      Top = 0
      Width = 16
      Height = 441
      Cursor = crHandPoint
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'pnlDetailSwitcher'
      ParentBackground = False
      ShowCaption = False
      TabOrder = 0
      OnClick = pnlDetailSwitcherClick
      object btnSwitcher: TSpeedButton
        Left = 0
        Top = 213
        Width = 16
        Height = 16
        Action = actSwitchPackageDetail
        Anchors = [akTop, akBottom]
        Flat = True
      end
    end
  end
  object ilIcons: TImageList
    Left = 540
    Top = 46
    Bitmap = {
      494C010102000800040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000007A7A7A0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000007A7A7A000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000007A7A7A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000007A7A7A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000007A7A7A000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000007A7A7A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000007A7A7A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000007A7A7A000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000007A7A7A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000007A7A7A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000007A7A7A000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000007A7A7A0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007A7A
      7A00000000000000000000000000000000000000000000000000000000000000
      00007A7A7A000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000007A7A
      7A00000000000000000000000000000000000000000000000000000000000000
      00007A7A7A000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000007A7A7A000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000007A7A7A0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000007A7A7A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000007A7A7A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000007A7A7A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000007A7A7A000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000007A7A7A000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000007A7A7A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000007A7A7A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000007A7A7A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000007A7A7A0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000007A7A7A000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFF00000000FBFFFFDF00000000
      F9FFFF9F00000000F8FFFF1F00000000F87FFE1F00000000F83FFC1F00000000
      F81FF81F00000000F80FF01F00000000F80FF01F00000000F81FF81F00000000
      F83FFC1F00000000F87FFE1F00000000F8FFFF1F00000000F9FFFF9F00000000
      FBFFFFDF00000000FFFFFFFF0000000000000000000000000000000000000000
      000000000000}
  end
  object alActions: TActionList
    Images = ilIcons
    Left = 540
    Top = 102
    object actSwitchPackageDetail: TAction
      ImageIndex = 1
    end
  end
end
