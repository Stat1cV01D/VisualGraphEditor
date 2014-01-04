object AllItemsForm: TAllItemsForm
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'AllItemsForm'
  ClientHeight = 235
  ClientWidth = 441
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Grid: TStringGrid
    Left = 8
    Top = 8
    Width = 425
    Height = 216
    ColCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing]
    ScrollBars = ssVertical
    TabOrder = 0
    OnGetEditMask = GridGetEditMask
    OnSelectCell = GridSelectCell
    OnSetEditText = GridSetEditText
    ColWidths = (
      118
      132
      148)
    RowHeights = (
      24
      24
      24
      24
      24)
  end
end
