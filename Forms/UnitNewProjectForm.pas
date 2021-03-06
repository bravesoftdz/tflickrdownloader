﻿{ *
  * Copyright (C) 2014-2015 ozok <ozok26@gmail.com>
  *
  * This file is part of TFlickrDownloader.
  *
  * TFlickrDownloader is free software: you can redistribute it and/or modify
  * it under the terms of the GNU General Public License as published by
  * the Free Software Foundation, either version 2 of the License, or
  * (at your option) any later version.
  *
  * TFlickrDownloader is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  * GNU General Public License for more details.
  *
  * You should have received a copy of the GNU General Public License
  * along with TFlickrDownloader.  If not, see <http://www.gnu.org/licenses/>.
  *
  * }

unit UnitNewProjectForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Mask,
  sCustomComboEdit, Vcl.StdCtrls, Vcl.Buttons, UnitCommonTypes, Vcl.ExtCtrls,
  UnitPhotoStreamPageCountExtractor, Vcl.Samples.Spin, JvExMask, JvSpin, JvToolEdit,
  sPanel, sButton, sComboBox, sBitBtn, sLabel, sEdit, sSkinProvider, sMaskEdit,
  sToolEdit, sSpinEdit;

type
  TNewProjectForm = class(TForm)
    ProjectNameEdit: TsEdit;
    CancelBtn: TsBitBtn;
    SaveBtn: TsBitBtn;
    PageLinkEdit: TsEdit;
    ImageTypeList: TsComboBox;
    GetPageCountBtn: TsButton;
    sPanel1: TsPanel;
    EndPageEdit: TsSpinEdit;
    OutputDirectoryEdit: TsDirectoryEdit;
    StartPageEdit: TsSpinEdit;
    SaveDialog1: TSaveDialog;
    sSkinProvider1: TsSkinProvider;
    procedure SaveBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure GetPageCountBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    // removes invalid chars from string
    function RemoveInvalidChars(const Str: string): string;
  public
    { Public declarations }
  end;

var
  NewProjectForm: TNewProjectForm;

implementation

{$R *.dfm}

uses UnitMain;

procedure TNewProjectForm.CancelBtnClick(Sender: TObject);
begin
  if (Length(PageLinkEdit.Text) > 0) or (Length(ProjectNameEdit.Text) > 0) or (Length(OutputDirectoryEdit.Text) > 0) then
  begin
    if ID_YES = Application.MessageBox('Some values are changed. Are you sure you don''t want to save them?', 'Warning', MB_ICONWARNING or MB_YESNO) then
    begin
      Self.Close;
    end;
  end
  else
  begin
    Self.Close;
  end;
end;

procedure TNewProjectForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MainForm.Enabled := true;
  MainForm.BringToFront;
end;

procedure TNewProjectForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    CancelBtnClick(Self);
end;

procedure TNewProjectForm.GetPageCountBtnClick(Sender: TObject);
var
  LPCE: TPhotoStreamPageCountExtractor;
begin
  if DirectoryExists(OutputDirectoryEdit.Text) and (Length(PageLinkEdit.Text) > 0) then
  begin
    sPanel1.Visible := true;
    sPanel1.BringToFront;
    Self.Enabled := False;
    try
      // remove https
      PageLinkEdit.Text := StringReplace(PageLinkEdit.Text, 'http://', 'https://', [rfIgnoreCase]);

      LPCE := TPhotoStreamPageCountExtractor.Create(PageLinkEdit.Text, MainForm.TempFolder + '\pagecount.txt');
      try
        LPCE.Start();
        while LPCE.ExtractorStatus = pceDownloading do
        begin
          Application.ProcessMessages;
          Sleep(50);
        end;
        EndPageEdit.Value := LPCE.LastPage;
        StartPageEdit.Text := '1';
      finally
        LPCE.Free;
      end;
    finally
      sPanel1.Visible := False;
      Self.Enabled := true;
    end;
  end
  else
  begin
    Application.MessageBox('Please enter a valid output and link first.', 'Warning', MB_ICONWARNING);
  end;
end;

function TNewProjectForm.RemoveInvalidChars(const Str: string): string;
const
  InvalidChars = ['<', '>', ':', '"', '|', '/', '?', '*'];
var
  TmpStr: string;
  C: Char;
begin
  Result := Str;
  for C in Str do
  begin
    Application.ProcessMessages;
    if not CharInSet(C, InvalidChars) then
    begin
      TmpStr := TmpStr + C;
    end;
  end;
  if Length(TmpStr) > 0 then
  begin
    Result := TmpStr;
  end;
end;

procedure TNewProjectForm.SaveBtnClick(Sender: TObject);
var
  LProjectFile: TStringList;
  LProjectInfo: TProjectInfo;
begin
  if Length(PageLinkEdit.Text) > 0 then
  begin
    if Length(ProjectNameEdit.Text) > 0 then
    begin

      if not DirectoryExists(OutputDirectoryEdit.Text) then
      begin
        if not ForceDirectories(OutputDirectoryEdit.Text) then
        begin
          Application.MessageBox('Please specify a valid output folder.', 'Warning', MB_ICONWARNING);
          Exit;
        end;
      end;
      // remove https
      PageLinkEdit.Text := StringReplace(PageLinkEdit.Text, 'http://', 'https://', [rfIgnoreCase]);

      if (Length(StartPageEdit.Text) > 0) and (Length(EndPageEdit.Text) > 0) then
      begin
        if EndPageEdit.Value >= StartPageEdit.Value then
        begin
          LProjectFile := TStringList.Create;
          try
            LProjectFile.Add(ProjectNameEdit.Text);
            LProjectFile.Add(StartPageEdit.Text);
            LProjectFile.Add(EndPageEdit.Text);
            LProjectFile.Add(FloatToStr(ImageTypeList.ItemIndex));
            LProjectFile.Add(OutputDirectoryEdit.Text);
            LProjectFile.Add(StringReplace(PageLinkEdit.Text, 'http://', 'https://', []));

            if SaveDialog1.Execute then
            begin
              LProjectFile.SaveToFile(ExtractFileDir(SaveDialog1.FileName) + '\' + ChangeFileExt(RemoveInvalidChars(ExtractFileName(SaveDialog1.FileName)), '.fpd'), TEncoding.UTF8);
            end;
          finally
            FreeAndNil(LProjectFile);

            MainForm.CloseProjectBtnClick(Self);
            // update main form
            if MainForm.LoadProject(ExtractFileDir(SaveDialog1.FileName) + '\' + ChangeFileExt(RemoveInvalidChars(ExtractFileName(SaveDialog1.FileName)), '.fpd'), LProjectInfo) then
            begin
              MainForm.ProjectInfo := LProjectInfo;
              MainForm.ProjectLoadedStatus;
              MainForm.ProjectFilePath := ExtractFileDir(SaveDialog1.FileName) + '\' + ChangeFileExt(RemoveInvalidChars(ExtractFileName(SaveDialog1.FileName)), '.fpd');
            end
            else
            begin
              Application.MessageBox('Cannot load project file!', 'Error', MB_ICONERROR);
              MainForm.ProjectUnLoadedStatus;
            end;
            Self.Close;
          end;
        end;
      end
      else
      begin
        Application.MessageBox('Please enter valid start/end page values.', 'Warning', MB_ICONWARNING);
      end;

    end
    else
    begin
      Application.MessageBox('Please specify a valid project name.', 'Warning', MB_ICONWARNING);
    end;
  end
  else
  begin
    Application.MessageBox('Please enter a valid Flickr link.', 'Warning', MB_ICONWARNING)
  end;
end;

end.
