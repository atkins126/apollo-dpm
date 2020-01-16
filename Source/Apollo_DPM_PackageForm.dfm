object PackageForm: TPackageForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'PackageForm'
  ClientHeight = 456
  ClientWidth = 415
  Color = clBtnFace
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object leRepoURL: TLabeledEdit
    Left = 95
    Top = 8
    Width = 276
    Height = 21
    EditLabel.Width = 90
    EditLabel.Height = 13
    EditLabel.Caption = 'GitHub Repo URL'
    LabelPosition = lpLeft
    TabOrder = 0
  end
  object btnGo: TButton
    Left = 374
    Top = 6
    Width = 37
    Height = 25
    Caption = 'Go'
    TabOrder = 1
    OnClick = btnGoClick
  end
  object leOwner: TLabeledEdit
    Left = 95
    Top = 39
    Width = 250
    Height = 21
    EditLabel.Width = 35
    EditLabel.Height = 13
    EditLabel.Caption = 'Owner'
    LabelPosition = lpLeft
    ReadOnly = True
    TabOrder = 2
  end
  object leRepo: TLabeledEdit
    Left = 95
    Top = 66
    Width = 250
    Height = 21
    EditLabel.Width = 27
    EditLabel.Height = 13
    EditLabel.Caption = 'Repo'
    LabelPosition = lpLeft
    ReadOnly = True
    TabOrder = 3
  end
  object leName: TLabeledEdit
    Left = 95
    Top = 93
    Width = 250
    Height = 21
    EditLabel.Width = 29
    EditLabel.Height = 13
    EditLabel.Caption = 'Name'
    LabelPosition = lpLeft
    TabOrder = 4
  end
  object leDescription: TLabeledEdit
    Left = 95
    Top = 120
    Width = 250
    Height = 21
    EditLabel.Width = 59
    EditLabel.Height = 13
    EditLabel.Caption = 'Description'
    LabelPosition = lpLeft
    TabOrder = 5
  end
  object grpFiltering: TGroupBox
    Left = 3
    Top = 153
    Width = 200
    Height = 249
    Caption = 'Filtering'
    TabOrder = 6
    object rbBlackList: TRadioButton
      Left = 103
      Top = 16
      Width = 70
      Height = 17
      Caption = 'Black list'
      TabOrder = 0
    end
    object rbWhiteList: TRadioButton
      Left = 27
      Top = 16
      Width = 70
      Height = 17
      Caption = 'White list'
      Checked = True
      TabOrder = 1
      TabStop = True
    end
    object mmoFiltering: TMemo
      Left = 5
      Top = 36
      Width = 190
      Height = 207
      TabOrder = 2
    end
  end
  object grpMoving: TGroupBox
    Left = 208
    Top = 153
    Width = 200
    Height = 249
    Caption = 'Moving'
    TabOrder = 7
    object sgMoving: TStringGrid
      Left = 5
      Top = 36
      Width = 190
      Height = 207
      ColCount = 2
      DefaultRowHeight = 21
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goAlwaysShowEditor]
      TabOrder = 0
      OnKeyDown = sgMovingKeyDown
      ColWidths = (
        93
        83)
    end
  end
end
