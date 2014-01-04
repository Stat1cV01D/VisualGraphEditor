object EdgeEditForm: TEdgeEditForm
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Edit Edge'
  ClientHeight = 66
  ClientWidth = 235
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object LabeledEdit1: TLabeledEdit
    Left = 8
    Top = 24
    Width = 121
    Height = 21
    EditLabel.Width = 50
    EditLabel.Height = 13
    EditLabel.Caption = #1042#1077#1089' '#1088#1077#1073#1088#1072
    MaxLength = 5
    NumbersOnly = True
    TabOrder = 0
    Text = '1'
    OnKeyPress = LabeledEdit1KeyPress
  end
  object Button1: TButton
    Left = 144
    Top = 22
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = Button1Click
  end
end
