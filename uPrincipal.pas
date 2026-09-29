unit uPrincipal;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, FileCtrl,
  ComCtrls, Gauges, AppEvnts, Menus, ActnList, StdActns, ShellAPI,
  sSkinManager, sStatusBar, sPageControl, sEdit, sBitBtn, sLabel,
  sPanel, sRadioButton, sButton, sSpinEdit, sComboBox, sListView, sSplitter,
  Mask, sMaskEdit, sCustomComboEdit, Buttons;

type
  TfrmPrincipal = class(TForm)
    stbTarget: TsStatusBar;
    PageControl1: TsPageControl;
    TabSheet1: TsTabSheet;
    TabSheet2: TsTabSheet;
    TabSheet3: TsTabSheet;
    Edit1: TsEdit;
    Edit2: TsEdit;
    btnReplace: TsBitBtn;
    Label1: TLabel;
    Label2: TsLabel;
    Panel1: TsPanel;
    dlbtarget: TDirectoryListBox;
    Panel2: TsPanel;
    dcbtarget: TDriveComboBox;
    rbt: TsRadioButton;
    RadioButton2: TsRadioButton;
    btnCaixa: TsButton;
    edtNomePadrao: TsEdit;
    Label4: TLabel;
    btnNomePadrao: TsButton;
    sedNumIni: TsSpinEdit;
    sedLength: TsSpinEdit;
    Label5: TsLabel;
    Label6: TsLabel;
    cmbOp: TsComboBox;
    Label7: TsLabel;
    ApplicationEvents1: TApplicationEvents;
    lvwTarget: TsListView;
    Splitter1: TsSplitter;
    Panel3: TsPanel;
    gBarra: TGauge;
    sSkinManager1: TsSkinManager;
    MainMenu1: TMainMenu;
    Arquivo1: TMenuItem;
    Sair1: TMenuItem;
    Ferramentas1: TMenuItem;
    AlphaControlsSkyns1: TMenuItem;
    ActionList1: TActionList;
    WindowClose1: TWindowClose;
    procedure btnReplaceClick(Sender: TObject);
    procedure btnNomePadraoClick(Sender: TObject);
    procedure btnCaixaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cmbOpChange(Sender: TObject);
    procedure dlbtargetChange(Sender: TObject);
    procedure lvwTargetDblClick(Sender: TObject);
    procedure lvwTargetSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvwTargetEdited(Sender: TObject; Item: TListItem; var S: string);
  private
    { Private declarations }
    procedure AtualizarListaArquivos;
    function FormatarTamanho(Bytes: Int64): string;
    function ToTitleCase(const S: string): string;
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.DFM}

function TfrmPrincipal.FormatarTamanho(Bytes: Int64): string;
begin
  if Bytes < 1024 then
    Result := IntToStr(Bytes) + ' B'
  else if Bytes < 1024 * 1024 then
    Result := Format('%.1f KB', [Bytes / 1024.0])
  else
    Result := Format('%.1f MB', [Bytes / (1024.0 * 1024.0)]);
end;

function TfrmPrincipal.ToTitleCase(const S: string): string;
var
  i: Integer;
  CapitalizeNext: Boolean;
begin
  Result := AnsiLowerCase(S);
  CapitalizeNext := True;
  for i := 1 to Length(Result) do
  begin
    if Result[i] in [' ', '_', '-', '.'] then
      CapitalizeNext := True
    else if CapitalizeNext then
    begin
      Result[i] := AnsiUpperCase(Result[i])[1];
      CapitalizeNext := False;
    end;
  end;
end;

procedure TfrmPrincipal.AtualizarListaArquivos;
var
  SearchRec: TSearchRec;
  Path: string;
  Item: TListItem;
  TotalCount: Integer;
begin
  lvwTarget.Items.BeginUpdate;
  try
    lvwTarget.Items.Clear;
    Path := IncludeTrailingPathDelimiter(dlbtarget.Directory);
    TotalCount := 0;

    if FindFirst(Path + '*.*', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
        begin
          Item := lvwTarget.Items.Add;
          Item.Caption := SearchRec.Name;
          Item.SubItems.Add(FormatarTamanho(SearchRec.Size));
          Item.SubItems.Add(Path + SearchRec.Name);
          Inc(TotalCount);
        end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  finally
    lvwTarget.Items.EndUpdate;
  end;

  stbTarget.SimpleText := Format('Total de arquivos na pasta: %d', [TotalCount]);
  gBarra.Progress := 0;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  lvwTarget.ViewStyle := vsReport;
  lvwTarget.GridLines := True;

  if lvwTarget.Columns.Count = 0 then
  begin
    with lvwTarget.Columns.Add do
    begin
      Caption := 'Nome';
      Width := 220;
    end;
    with lvwTarget.Columns.Add do
    begin
      Caption := 'Tamanho';
      Width := 90;
    end;
    with lvwTarget.Columns.Add do
    begin
      Caption := 'Caminho Completo';
      Width := 350;
    end;
  end;

  if sedNumIni.Value < 1 then
    sedNumIni.Value := 1;
  if sedLength.Value < 1 then
    sedLength.Value := 2;

  AtualizarListaArquivos;
end;

procedure TfrmPrincipal.dlbtargetChange(Sender: TObject);
begin
  AtualizarListaArquivos;
end;

procedure TfrmPrincipal.btnReplaceClick(Sender: TObject);
var
  i: Integer;
  OldName, NewName, OldPath, NewPath, SearchStr, ReplaceStr: string;
  Path: string;
  RenamedCount: Integer;
begin
  SearchStr := Edit1.Text;
  ReplaceStr := Edit2.Text;

  if SearchStr = '' then
  begin
    ShowMessage('Informe o texto a ser localizado para substituição.');
    Exit;
  end;

  Path := IncludeTrailingPathDelimiter(dlbtarget.Directory);
  RenamedCount := 0;
  gBarra.MinValue := 0;
  gBarra.MaxValue := lvwTarget.Items.Count;
  gBarra.Progress := 0;

  for i := 0 to lvwTarget.Items.Count - 1 do
  begin
    OldName := lvwTarget.Items[i].Caption;
    if Pos(AnsiUpperCase(SearchStr), AnsiUpperCase(OldName)) > 0 then
    begin
      NewName := StringReplace(OldName, SearchStr, ReplaceStr, [rfReplaceAll, rfIgnoreCase]);
      OldPath := Path + OldName;
      NewPath := Path + NewName;

      if (OldName <> NewName) and RenameFile(OldPath, NewPath) then
      begin
        lvwTarget.Items[i].Caption := NewName;
        lvwTarget.Items[i].SubItems[1] := NewPath;
        Inc(RenamedCount);
      end;
    end;
    gBarra.Progress := i + 1;
  end;

  ShowMessage(Format('Substituição concluída! %d arquivo(s) renomeado(s).', [RenamedCount]));
  AtualizarListaArquivos;
end;

procedure TfrmPrincipal.btnNomePadraoClick(Sender: TObject);
var
  i: Integer;
  BaseName, OldName, NewName, Ext, NameOnly, NumberStr: string;
  Path, OldPath, NewPath: string;
  StartNum, NumDigits, Mode, RenamedCount: Integer;
begin
  BaseName := edtNomePadrao.Text;
  StartNum := sedNumIni.Value;
  NumDigits := sedLength.Value;
  Mode := cmbOp.ItemIndex;
  Path := IncludeTrailingPathDelimiter(dlbtarget.Directory);
  RenamedCount := 0;

  gBarra.MinValue := 0;
  gBarra.MaxValue := lvwTarget.Items.Count;
  gBarra.Progress := 0;

  for i := 0 to lvwTarget.Items.Count - 1 do
  begin
    OldName := lvwTarget.Items[i].Caption;
    Ext := ExtractFileExt(OldName);
    NameOnly := ChangeFileExt(OldName, '');
    NumberStr := Format('%.*d', [NumDigits, StartNum + i]);

    case Mode of
      0: // Sufixo
        if BaseName <> '' then
          NewName := BaseName + '_' + NumberStr + Ext
        else
          NewName := NameOnly + '_' + NumberStr + Ext;
      1: // Prefixo
        if BaseName <> '' then
          NewName := NumberStr + '_' + BaseName + Ext
        else
          NewName := NumberStr + '_' + NameOnly + Ext;
      2: // Substituir completo
        NewName := BaseName + NumberStr + Ext;
    else
      if BaseName <> '' then
        NewName := BaseName + '_' + NumberStr + Ext
      else
        NewName := NameOnly + '_' + NumberStr + Ext;
    end;

    OldPath := Path + OldName;
    NewPath := Path + NewName;

    if (OldName <> NewName) and RenameFile(OldPath, NewPath) then
    begin
      lvwTarget.Items[i].Caption := NewName;
      lvwTarget.Items[i].SubItems[1] := NewPath;
      Inc(RenamedCount);
    end;

    gBarra.Progress := i + 1;
  end;

  ShowMessage(Format('Sequência de nomes aplicada! %d arquivo(s) renomeado(s).', [RenamedCount]));
  AtualizarListaArquivos;
end;

procedure TfrmPrincipal.btnCaixaClick(Sender: TObject);
var
  i: Integer;
  OldName, NewName, NameOnly, Ext, Path, OldPath, NewPath: string;
  RenamedCount: Integer;
begin
  Path := IncludeTrailingPathDelimiter(dlbtarget.Directory);
  RenamedCount := 0;

  gBarra.MinValue := 0;
  gBarra.MaxValue := lvwTarget.Items.Count;
  gBarra.Progress := 0;

  for i := 0 to lvwTarget.Items.Count - 1 do
  begin
    OldName := lvwTarget.Items[i].Caption;
    Ext := ExtractFileExt(OldName);
    NameOnly := ChangeFileExt(OldName, '');

    if rbt.Checked then
      NewName := AnsiUpperCase(NameOnly) + AnsiLowerCase(Ext)
    else if RadioButton2.Checked then
      NewName := AnsiLowerCase(NameOnly) + AnsiLowerCase(Ext)
    else
      NewName := ToTitleCase(NameOnly) + AnsiLowerCase(Ext);

    OldPath := Path + OldName;
    NewPath := Path + NewName;

    if (OldName <> NewName) and RenameFile(OldPath, NewPath) then
    begin
      lvwTarget.Items[i].Caption := NewName;
      lvwTarget.Items[i].SubItems[1] := NewPath;
      Inc(RenamedCount);
    end;

    gBarra.Progress := i + 1;
  end;

  ShowMessage(Format('Alteração de caixa concluída! %d arquivo(s) renomeado(s).', [RenamedCount]));
  AtualizarListaArquivos;
end;

procedure TfrmPrincipal.cmbOpChange(Sender: TObject);
begin
  // Atualizações dinâmicas na interface se necessário
end;

procedure TfrmPrincipal.lvwTargetDblClick(Sender: TObject);
var
  FilePath: string;
begin
  if Assigned(lvwTarget.Selected) then
  begin
    FilePath := IncludeTrailingPathDelimiter(dlbtarget.Directory) + lvwTarget.Selected.Caption;
    ShellExecute(Handle, 'open', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TfrmPrincipal.lvwTargetSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) then
    stbTarget.SimpleText := Format('Selecionado: %s (%s)', [Item.Caption, Item.SubItems[0]])
  else
    stbTarget.SimpleText := Format('Total de arquivos na pasta: %d', [lvwTarget.Items.Count]);
end;

procedure TfrmPrincipal.lvwTargetEdited(Sender: TObject; Item: TListItem; var S: string);
var
  OldPath, NewPath, Path: string;
begin
  if (S <> '') and (S <> Item.Caption) then
  begin
    Path := IncludeTrailingPathDelimiter(dlbtarget.Directory);
    OldPath := Path + Item.Caption;
    NewPath := Path + S;

    if RenameFile(OldPath, NewPath) then
    begin
      if Item.SubItems.Count > 1 then
        Item.SubItems[1] := NewPath;
    end
    else
    begin
      ShowMessage('Não foi possível renomear o arquivo.');
      S := Item.Caption;
    end;
  end;
end;

procedure TfrmPrincipal.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
    AtualizarListaArquivos;
end;

end.