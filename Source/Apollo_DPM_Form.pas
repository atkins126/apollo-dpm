unit Apollo_DPM_Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.WinXCtrls,
  Apollo_DPM_Engine,
  Apollo_DPM_Package;

type
  TGetVersionsFunc = function(aPackage: TPackage): TArray<TVersion> of object;
  TActionProc = procedure(const aVersionName: string; aPackage: TPackage) of object;

  TDPMForm = class(TForm)
    pnlMain: TPanel;
    sbPackages: TScrollBox;
    tvStructure: TTreeView;
    splStruct2Grid: TSplitter;
    aiPabPkgLoad: TActivityIndicator;
    mmoActionLog: TMemo;
    splMain2Log: TSplitter;
    pnlButtons: TPanel;
    pnlContent: TPanel;
    btnNewPackage: TButton;
    procedure tvStructureCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure tvStructureChange(Sender: TObject; Node: TTreeNode);
    procedure btnNewPackageClick(Sender: TObject);
  private
    { Private declarations }
    FDPMEngine: TDPMEngine;
    FPackageFrames: TArray<TFrame>;
    function GetVersionsFunc(aPackage: TPackage): TArray<TVersion>;
    procedure ActionProc(const aVersionName: string; aPackage: TPackage);
    procedure AsyncLoadPublicPackages;
    procedure ClearPackageFrames;
    procedure RenderPackageList(aPackageList: TPackageList);
    procedure RenderStructureTree;
  public
    { Public declarations }
    procedure NotifyListener(const aMsg: string);
    constructor Create(aDPMEngine: TDPMEngine); reintroduce;
  end;

const
  cProjectDependencies = 'Project Dependencies';
  cIDEDependencies = 'IDE Dependencies';
  cPublicPackages = 'Public Packages';

var
  DPMForm: TDPMForm;

implementation

{$R *.dfm}

uses
  Apollo_DPM_PackageForm,
  Apollo_DPM_PackageFrame,
  System.Threading;

{ TDPMForm }

procedure TDPMForm.ActionProc(const aVersionName: string; aPackage: TPackage);
begin
  FDPMEngine.InstallPackage(aVersionName, aPackage);
end;

procedure TDPMForm.AsyncLoadPublicPackages;
var
  AsyncTask: ITask;
  PublicPackages: TPackageList;
begin
  AsyncTask := TTask.Create(procedure()
    begin
      PublicPackages := FDPMEngine.GetPublicPackages;

      TThread.Synchronize(nil, procedure()
        begin
          aiPabPkgLoad.Animate := False;
          RenderPackageList(PublicPackages);
        end
      );
    end
  );
  AsyncTask.Start;
end;

procedure TDPMForm.btnNewPackageClick(Sender: TObject);
var
  Package: TPackage;
  PackageForm: TPackageForm;
begin
  Package := TPackage.Create;
  PackageForm := TPackageForm.Create(FDPMEngine, Package);
  try
    PackageForm.ShowModal;
  finally
    PackageForm.Free;
    Package.Free;
  end;
end;

procedure TDPMForm.ClearPackageFrames;
var
  i: Integer;
begin
  for i := 0 to Length(FPackageFrames) - 1 do
    FPackageFrames[i].Free;

  FPackageFrames := [];
end;

constructor TDPMForm.Create(aDPMEngine: TDPMEngine);
begin
  inherited Create(nil);

  FDPMEngine := aDPMEngine;

  FPackageFrames := [];
  RenderStructureTree;
end;

function TDPMForm.GetVersionsFunc(aPackage: TPackage): TArray<TVersion>;
begin
  Result := FDPMEngine.GetPackageVersions(aPackage);
end;

procedure TDPMForm.NotifyListener(const aMsg: string);
begin
  mmoActionLog.Lines.Add(aMsg);
end;

procedure TDPMForm.RenderPackageList(aPackageList: TPackageList);
var
  i: Integer;
  Package: TPackage;
  PackageFrame: TfrmPackage;
  Top: Integer;
begin
  i := 0;
  Top := 0;

  for Package in aPackageList do
    begin
      PackageFrame := TfrmPackage.Create(sbPackages, Package);
      PackageFrame.Name := Format('PackageFrame%d', [i]);
      PackageFrame.Parent := sbPackages;
      PackageFrame.Top := Top;
      PackageFrame.Left := 0;
      PackageFrame.GetVersionsFunc := GetVersionsFunc;
      PackageFrame.ActionProc := ActionProc;
      if not Odd(i) then
        PackageFrame.Color := clBtnFace;

      Inc(i);
      Top := Top + PackageFrame.Height + 1;
      FPackageFrames := FPackageFrames + [PackageFrame];
    end;
end;

procedure TDPMForm.RenderStructureTree;
begin
  tvStructure.Items.Add(nil, cProjectDependencies);
  tvStructure.Items.Add(nil, cIDEDependencies);
  tvStructure.Items.Add(nil, cPublicPackages);
end;

procedure TDPMForm.tvStructureChange(Sender: TObject; Node: TTreeNode);
begin
  ClearPackageFrames;

  if Node.Text = cPublicPackages then
    begin
      aiPabPkgLoad.Animate := True;
      AsyncLoadPublicPackages;
    end
  else
  if FDPMEngine.IsProjectOpened and (Node.Text = cProjectDependencies) then
    RenderPackageList(FDPMEngine.GetProjectPackageList);
end;

procedure TDPMForm.tvStructureCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Rect: TRect;
begin
  DefaultDraw := False;

  if cdsSelected in State then
    begin
      Sender.Canvas.Brush.Color := clHighlight;
      Sender.Canvas.Font.Color := clHighlightText;
    end
  else
    begin
      Sender.Canvas.Brush.Color := clWindow;
      Sender.Canvas.Font.Color := clWindowText;
    end;

  Rect := Node.DisplayRect(False);
  Sender.Canvas.FillRect(Rect);

  Rect := Node.DisplayRect(True);
  Sender.Canvas.TextOut(Rect.Left, Rect.Top, Node.Text);
end;

end.
