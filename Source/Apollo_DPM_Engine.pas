unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  TUINotifyProc = procedure(const aMsg: string) of object;
  TUIUpdateProc = procedure(aPackage: TPackage) of object;
  TUIGetFolderFunc = function: string of object;

  TDPMEngine = class;

  TCompileNotifier = class(TInterfacedObject, IOTACompileNotifier)
  private
    FDPMEngine: TDPMEngine;
  protected
    procedure ProjectCompileStarted(const Project: IOTAProject; Mode: TOTACompileMode);
    procedure ProjectCompileFinished(const Project: IOTAProject; Result: TOTACompileResult);
    procedure ProjectGroupCompileStarted(Mode: TOTACompileMode);
    procedure ProjectGroupCompileFinished(Result: TOTACompileResult);
  end;

  TActionType = (atAdd, atRemove, atUpgrade, atPackageSettings);

  TDPMEngine = class
  private
    FCompileServices: IOTACompileServices;
    FGHAPI: TGHAPI;
    FNotifierIndex: Integer;
    FNTAServices: INTAServices;
    FProjectPackages: TPackageList;
    FPublicPackages: TPackageList;
    FUIGetFolder: TUIGetFolderFunc;
    FUINotifyProc: TUINotifyProc;
    function AddPackageFiles(const aDispalyVersionName, aPackagePath: string; aPackage: TPackage): TArray<string>;
    function CreatePackageList(const aJSONString: string): TPackageList;
    function GetActiveProject: IOTAProject;
    function GetActiveProjectPath: string;
    function GetApolloMenuItem: TMenuItem;
    function GetFileSize(const aPath: string): Int64;
    function GetFullPath(const aBasePath, aRelativePath: string): string;
    function GetIDEMainMenu: TMainMenu;
    function GetPackageFiles(aPackage: TPackage; const aDirectoryPattren, aFilePattren: string): TArray<string>;
    function GetPackagePath(aPackage: TPackage): string;
    function GetPackagesJSONString(aPackageList: TPackageList): string;
    function GetProjectConfigTargetPaths(aProjectConfig :IOTABuildConfiguration): TArray<string>;
    function GetProjectPackagesFilePath: string;
    function GetSelectedVersionSHA(const aDisplayVersionName: string; aPackage: TPackage;
      out aVersionName: string): string;
    function GetVendorsPath: string;
    function SaveContent(const aVendorPath, aRepoPath, aContent: string): string;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure AddSourceLib(const aDisplayVersionName: string; aPackage: TPackage);
    procedure AddTemplate(const aDisplayVersionName: string; aPackage: TPackage);
    procedure BuildBIN(const aTargetPath: string);
    procedure BuildMenu;
    procedure DeletePackagePath(aPackage: TPackage);
    procedure DPMMenuItemClick(Sender: TObject);
    procedure OpenProject(const aProjectPath: string);
    procedure RemovePackageFromActiveProject(aPackage: TPackage);
    procedure RemovePackageFromBIN(aPackage: TPackage);
    procedure WriteFile(const aFilePath: string; aBytes: TBytes);
  public
    function AllowAction(aPackage: TPackage; const aActionType: TActionType): Boolean;
    function GetProjectPackageList: TPackageList;
    function GetPublicPackages: TPackageList;
    function GetPackageVersions(aPackage: TPackage): TArray<TVersion>;
    function IsProjectOpened: Boolean;
    function LoadRepoData(const aRepoURL: string; out aOwner, aRepo, aError: string): Boolean;
    procedure AddPackage(const aDispalyVersionName: string; aPackage: TPackage);
    procedure RemovePackage(aPackage: TPackage);
    procedure SavePackage(aPackage: TPackage; const aPath: string);  //need for publish package
    procedure SavePackages(aPackageList: TPackageList; const aPath: string);
    constructor Create(aBorlandIDEServices: IBorlandIDEServices);
    destructor Destroy; override;
  end;

const
  cApolloDPMPublicPackagesPath = '/master/Public/PublicPackages.json';
  cApolloDPMPrivatePackagesPath = 'PrivatePackages.json';
  cApolloDPMProjectPackagesPath = 'ProjectPackages.json';
  cApolloDPMRepo = 'apollo-dpm';
  cApolloLibOwner = 'apollo-delphi';
  cApolloMenuItemCaption = 'Apollo';
  cApolloMenuItemName = 'miApollo';
  cDPMMenuItemCaption = 'DPM - Delphi Package Manager...';

  cEmptyPackagesFileContent = '{"packages": []}';

  cCustomRevision = 'rev.';
  cLatestVersion = 'latest version';
  cLatestRevision = 'latest revision';

implementation

uses
  Apollo_DPM_Form,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.NetEncoding;

{ TDPMEngine }

procedure TDPMEngine.AddApolloMenuItem;
var
  ApolloItem: TMenuItem;
begin
  ApolloItem := TMenuItem.Create(nil);
  ApolloItem.Name := cApolloMenuItemName;
  ApolloItem.Caption := cApolloMenuItemCaption;

  GetIDEMainMenu.Items.Insert(GetIDEMainMenu.Items.Count - 1, ApolloItem);
end;

procedure TDPMEngine.AddDPMMenuItem;
var
  DPMMenuItem: TMenuItem;
begin
  DPMMenuItem := TMenuItem.Create(nil);
  DPMMenuItem.Caption := cDPMMenuItemCaption;
  DPMMenuItem.OnClick := DPMMenuItemClick;

  GetApolloMenuItem.Add(DPMMenuItem);
end;

function TDPMEngine.AllowAction(aPackage: TPackage;
  const aActionType: TActionType): Boolean;
var
  ProjectPackageList: TPackageList;
begin
  Result := False;

  if IsProjectOpened then
    begin
      ProjectPackageList := GetProjectPackageList;

      case aActionType of
        atAdd: Result := not ProjectPackageList.Contains(aPackage);
        atRemove: Result := ProjectPackageList.Contains(aPackage);
      end;
    end
  else
    if (aActionType = atAdd) and (aPackage.PackageType = ptTemplate) then
      Result := True;

  case aActionType of
    atPackageSettings: Result := True;
  end;
end;

procedure TDPMEngine.BuildBIN(const aTargetPath: string);
var
  Files: TArray<string>;
  Package: TPackage;
  ProjectPackages: TPackageList;
  sFile: string;
  sTargetFile: string;
begin
  ForceDirectories(aTargetPath);
  ProjectPackages := GetProjectPackageList;

  for Package in ProjectPackages do
    begin
      Files := GetPackageFiles(Package, 'BIN', '*');

      for sFile in Files do
        begin
          sTargetFile := aTargetPath + '\' + TPath.GetFileName(sFile);
          if (not TFile.Exists(sTargetFile)) or
             (TFile.Exists(sTargetFile) and (GetFileSize(sTargetFile) <> GetFileSize(sFile)))
          then
            TFile.Copy(sFile, sTargetFile, True);
        end;
    end;
end;

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create(aBorlandIDEServices: IBorlandIDEServices);
var
  CompileNotifier: TCompileNotifier;
begin
  FNTAServices := aBorlandIDEServices as INTAServices;

  FCompileServices := BorlandIDEServices as IOTACompileServices;
  CompileNotifier := TCompileNotifier.Create;
  CompileNotifier.FDPMEngine := Self;
  FNotifierIndex := FCompileServices.AddNotifier(CompileNotifier);

  FGHAPI := TGHAPI.Create;
  FPublicPackages := nil;
  FProjectPackages := nil;

  if FNTAServices = nil then
    Exit;

  BuildMenu;
end;

function TDPMEngine.LoadRepoData(const aRepoURL: string; out aOwner, aRepo, aError: string): Boolean;
var
  RepoURL: string;
  SHA: string;
  URLWords: TArray<string>;
begin
  Result := False;
  RepoURL := aRepoURL;
  aOwner := '';
  aRepo := '';
  aError := '';

  if RepoURL.Contains('://') then
    RepoURL := RepoURL.Substring(RepoURL.IndexOf('://') + 3, RepoURL.Length);
  URLWords := RepoURL.Split(['/']);

  if (not (Length(URLWords) >= 3)) or
   ((Length(URLWords) > 0) and (URLWords[0].ToLower <> 'github.com'))
  then
    begin
      aError := 'The repo URL is invalid!';
      Exit;
    end;

  try
    SHA := FGHAPI.GetMasterBranchSHA(URLWords[1], URLWords[2]);
  except
    aError := 'Can`t load the repo URL!';
    Exit;
  end;

  if SHA.IsEmpty then
    Exit;

  Result := True;
  aOwner := URLWords[1];
  aRepo := URLWords[2];
end;

procedure TDPMEngine.OpenProject(const aProjectPath: string);
var
  ModuleServices: IOTAModuleServices;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  ModuleServices.OpenModule(aProjectPath);
end;

procedure TDPMEngine.RemovePackage(aPackage: TPackage);
var
  ProjectPackageList: TPackageList;
begin
  RemovePackageFromActiveProject(aPackage);
  RemovePackageFromBIN(aPackage);
  DeletePackagePath(aPackage);

  ProjectPackageList := GetProjectPackageList;
  ProjectPackageList.Remove(aPackage);
  if ProjectPackageList.Count > 0 then
    SavePackages(ProjectPackageList, GetProjectPackagesFilePath)
  else
    TFile.Delete(GetProjectPackagesFilePath);
end;

procedure TDPMEngine.RemovePackageFromActiveProject(aPackage: TPackage);
var
  ActiveProject: IOTAProject;
  Files: TArray<string>;
  sFile: string;
begin
  ActiveProject := GetActiveProject;
  Files := GetPackageFiles(aPackage, '*', '*');

  for sFile in Files do
    if ActiveProject.FindModuleInfo(sFile) <> nil then
      ActiveProject.RemoveFile(sFile);
end;

procedure TDPMEngine.RemovePackageFromBIN(aPackage: TPackage);
var
  ActiveProject: IOTAProject;
  i: Integer;
  PackageBINFile: string;
  PackageBINFiles: TArray<string>;
  ProjectBINFile: string;
  ProjectBINFiles: TArray<string>;
  ProjectConfigTargetPaths: TArray<string>;
  ProjectOptionsConfigurations: IOTAProjectOptionsConfigurations;
  ProjectTargetPath: string;
begin
  PackageBINFiles := GetPackageFiles(aPackage, 'BIN', '*');
  if Length(PackageBINFiles) = 0 then
    Exit;

  ActiveProject := GetActiveProject;
  ProjectOptionsConfigurations := ActiveProject.ProjectOptions as IOTAProjectOptionsConfigurations;

  for i := 0 to ProjectOptionsConfigurations.ConfigurationCount - 1 do
    begin
      ProjectConfigTargetPaths := GetProjectConfigTargetPaths(ProjectOptionsConfigurations.Configurations[i]);

      ProjectBINFiles := [];
      for ProjectTargetPath in ProjectConfigTargetPaths do
        if TDirectory.Exists(ProjectTargetPath) then
          begin
            ProjectBINFiles := ProjectBINFiles + TDirectory.GetFiles(ProjectTargetPath, '*', TSearchOption.soAllDirectories);

            for PackageBINFile in PackageBINFiles do
              for ProjectBINFile in ProjectBINFiles do
                if TPath.GetFileName(PackageBINFile) = TPath.GetFileName(ProjectBINFile) then
                  begin
                    TFile.Delete(ProjectBINFile);
                    Break;
                  end;
          end;
    end;
end;

procedure TDPMEngine.DeletePackagePath(aPackage: TPackage);
begin
  TDirectory.Delete(GetPackagePath(aPackage), True);

  if Length(TDirectory.GetDirectories(GetVendorsPath, '*', TSearchOption.soTopDirectoryOnly)) = 0 then
    TDirectory.Delete(GetVendorsPath);
end;

destructor TDPMEngine.Destroy;
begin
  FCompileServices.RemoveNotifier(FNotifierIndex);

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  FGHAPI.Free;

  if Assigned(FPublicPackages) then
    FreeAndNil(FPublicPackages);

  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);

  inherited;
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
var
  DPMForm: TDPMForm;
begin
  DPMForm := TDPMForm.Create(Self);
  try
    FUINotifyProc := DPMForm.NotifyListener;
    FUIGetFolder := DPMForm.GetFolder;
    DPMForm.ShowModal;
  finally
    FUINotifyProc := nil;
    DPMForm.Free;
  end;
end;

function TDPMEngine.GetActiveProject: IOTAProject;
var
  i: Integer;
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Project: IOTAProject;
  ProjectGroup: IOTAProjectGroup;
begin
  Result := nil;

  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  for i := 0 to ModuleServices.ModuleCount - 1 do
    begin
      Module := ModuleServices.Modules[i];
      if Supports(Module, IOTAProjectGroup, ProjectGroup) then
        Exit(ProjectGroup.ActiveProject)
      else
      if Supports(Module, IOTAProject, Project) then
        Exit(Project);
    end;
end;

function TDPMEngine.GetActiveProjectPath: string;
begin
  Result := TDirectory.GetParent(GetActiveProject.FileName);
end;

function TDPMEngine.GetApolloMenuItem: TMenuItem;
var
  MenuItem: TMenuItem;
begin
  Result := nil;

  for MenuItem in GetIDEMainMenu.Items do
    if MenuItem.Name = cApolloMenuItemName then
      Exit(MenuItem);
end;

function TDPMEngine.GetFileSize(const aPath: string): Int64;
var
  FS: TFileStream;
begin
  FS := TFile.Open(aPath, TFileMode.fmOpen);
  try
    Result := FS.Size;
  finally
    FS.Free;
  end;
end;

function TDPMEngine.GetFullPath(const aBasePath, aRelativePath: string): string;
var
  Dirs: TArray<string>;
  i: Integer;
  ResultDirArr: TArray<string>;
  SkipDir: Boolean;
begin
  Result := TPath.Combine(aBasePath, aRelativePath);

  ResultDirArr := [];
  SkipDir := False;
  Dirs := Result.Split([TPath.DirectorySeparatorChar]);

  for i := Length(Dirs) - 1 downto 0 do
    begin
      if (Dirs[i] = '.') or (Dirs[i] = '..') then
        SkipDir := True;

      if not SkipDir then
        ResultDirArr := [Dirs[i]] + ResultDirArr;

      SkipDir := False;
      if Dirs[i] = '..' then
        SkipDir := True;
    end;

  Result := Result.Join(TPath.DirectorySeparatorChar, ResultDirArr);
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := FNTAServices.MainMenu;
end;

function TDPMEngine.CreatePackageList(const aJSONString: string): TPackageList;
var
  jsnPackageVal: TJSONValue;
  jsnPackagerArr: TJSONArray;
  jsnPackagesObj: TJSONObject;
  Package: TPackage;
begin
  Result := TPackageList.Create;

  jsnPackagesObj := TJSONObject.ParseJSONValue(aJSONString) as TJSONObject;
  try
    jsnPackagerArr := jsnPackagesObj.GetValue('packages') as TJSONArray;
    for jsnPackageVal in jsnPackagerArr do
      begin
        Package := TPackage.Create(jsnPackageVal as TJSONObject);
        Result.Add(Package);
      end;
  finally
    jsnPackagesObj.Free;
  end;
end;

function TDPMEngine.GetPackageFiles(aPackage: TPackage; const aDirectoryPattren,
  aFilePattren: string): TArray<string>;
var
  Directories: TArray<string>;
  Directory: string;
begin
  Result := [];
  Directories := TDirectory.GetDirectories(GetPackagePath(aPackage), aDirectoryPattren, TSearchOption.soAllDirectories);

  for Directory in Directories do
    Result := Result + TDirectory.GetFiles(Directory, aFilePattren, TSearchOption.soAllDirectories);
end;

function TDPMEngine.GetPackagePath(aPackage: TPackage): string;
begin
  Result := TPath.Combine(GetVendorsPath, aPackage.Name);

  if not TDirectory.Exists(Result) then
    ForceDirectories(Result);
end;

function TDPMEngine.GetPackagesJSONString(aPackageList: TPackageList): string;
var
  jsnPackageObj: TJSONObject;
  jsnPackagesObj: TJSONObject;
  jsnPackagerArr: TJSONArray;
  Package: TPackage;
begin
  jsnPackagesObj := TJSONObject.Create;
  try
    jsnPackagerArr := TJSONArray.Create;
    jsnPackagesObj.AddPair('packages', jsnPackagerArr);

    for Package in aPackageList do
      begin
        jsnPackageObj := Package.CreateJSON;
        jsnPackagerArr.AddElement(jsnPackageObj);
      end;

    Result := jsnPackagesObj.ToJSON;
  finally
    jsnPackagesObj.Free;
  end;
end;

function TDPMEngine.GetPackageVersions(aPackage: TPackage): TArray<TVersion>;
var
  Tag: TTag;
  Tags: TArray<TTag>;
  Version: TVersion;
begin
  Result := [];

  Tags := FGHAPI.GetRepoTags(aPackage.Owner, aPackage.Repo);

  for Tag in Tags do
    begin
      Version.Name := Tag.Name;
      Version.SHA := Tag.SHA;

      Result := Result + [Version];
    end;

  aPackage.Versions := Result;
end;

function TDPMEngine.GetProjectPackagesFilePath: string;
begin
  Result := GetActiveProjectPath + '\' + cApolloDPMProjectPackagesPath;
end;

function TDPMEngine.GetProjectConfigTargetPaths(aProjectConfig :IOTABuildConfiguration): TArray<string>;
const
  cConfig = '$(Config)';
  cPlatform = '$(Platform)';
var
  Platforms: TArray<string>;
  sPlatform: string;
  sResult: string;
begin
  Result := [];

  sResult := GetFullPath(GetActiveProjectPath, aProjectConfig.Value['DCC_ExeOutput']);
  sResult := sResult.Replace(cConfig, aProjectConfig.Name);

  if sResult.Contains(cPlatform) then
    begin
      Platforms := aProjectConfig.Platforms;

      for sPlatform in Platforms do
        Result := Result + [sResult.Replace(cPlatform, sPlatform)];
    end
  else
    Result := [sResult];
end;

function TDPMEngine.GetProjectPackageList: TPackageList;
var
  sPackagesJSON: string;
begin
  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);

  if not IsProjectOpened then
    Exit(nil);

  if not TFile.Exists(GetProjectPackagesFilePath) then
    sPackagesJSON := cEmptyPackagesFileContent
  else
    sPackagesJSON := TFile.ReadAllText(GetProjectPackagesFilePath, TEncoding.ANSI);

  Result := CreatePackageList(sPackagesJSON);
  FProjectPackages := Result;
end;

function TDPMEngine.GetPublicPackages: TPackageList;
var
  sPackagesJSON: string;
begin
  if FPublicPackages = nil then
    begin
      sPackagesJSON := FGHAPI.GetTextFileContent(
        cApolloLibOwner,
        cApolloDPMRepo,
        cApolloDPMPublicPackagesPath
      );

      Result := CreatePackageList(sPackagesJSON);

      FPublicPackages := Result;
    end
  else
    Result := FPublicPackages;
end;

function TDPMEngine.GetSelectedVersionSHA(const aDisplayVersionName: string; aPackage: TPackage;
  out aVersionName: string): string;
begin
  if aDisplayVersionName = cLatestVersion then
    begin
      GetPackageVersions(aPackage);
      if Length(aPackage.Versions) > 0 then
        begin
          Result := aPackage.Versions[0].SHA;
          aVersionName := aPackage.Versions[0].Name;
          Exit;
        end
    end;

  if (aDisplayVersionName = cLatestRevision) or (aDisplayVersionName = cLatestVersion) then
    begin
      Result := FGHAPI.GetMasterBranchSHA(aPackage.Owner, aPackage.Repo);
      aVersionName := cCustomRevision;
    end
  else
    begin
      Result := aPackage.Version[aDisplayVersionName].SHA;
      aVersionName := aPackage.Version[aDisplayVersionName].Name;
    end;
end;

function TDPMEngine.GetVendorsPath: string;
begin
  Result := TDirectory.GetParent(GetActiveProjectPath) + '\Vendors';

  if not TDirectory.Exists(Result) then
    ForceDirectories(Result);
end;

procedure TDPMEngine.AddPackage(const aDispalyVersionName: string; aPackage: TPackage);
begin
  case aPackage.PackageType of
    ptSource: AddSourceLib(aDispalyVersionName, aPackage);
    ptTemplate: AddTemplate(aDispalyVersionName, aPackage);
  end;
end;

function TDPMEngine.AddPackageFiles(const aDispalyVersionName, aPackagePath: string; aPackage: TPackage): TArray<string>;
var
  Blob: TBlob;
  FilePath: string;
  NodePath: string;
  RepoTree: TTree;
  TreeNode: TTreeNode;
  VersionName: string;
  VersionSHA: string;
begin
  Result := [];
  VersionSHA := GetSelectedVersionSHA(aDispalyVersionName, aPackage, VersionName);

  RepoTree := FGHAPI.GetRepoTree(aPackage.Owner, aPackage.Repo, VersionSHA);

  for TreeNode in RepoTree do
    begin
      if TreeNode.FileType <> 'blob' then
        Continue;

      if aPackage.AllowPath(TreeNode.Path) then
        begin
          Blob := FGHAPI.GetRepoBlob(TreeNode.URL);

          NodePath := aPackage.ApplyMoves(TreeNode.Path);
          FilePath := SaveContent(aPackagePath, NodePath, Blob.Content);

          Result := Result + [FilePath];
        end;
    end;
end;

procedure TDPMEngine.AddSourceLib(const aDisplayVersionName: string;
  aPackage: TPackage);
{var
  AddedPackage: TPackage;
  AddedVersion: TVersion;
  Blob: TBlob;
  Extension: string;
  FilePath: string;
  NodePath: string;
  PackagePath: string;
  ProjectPackageList: TPackageList;
  RepoTree: TTree;
  TreeNode: TTreeNode;
  VersionName: string;
  VersionSHA: string;}
var
  PackagePath: string;
begin
  {if aPackage.PackageType = ptTemplate then
    PackagePath := FUIGetFolder
  else
    PackagePath := GetPackagePath(aPackage);

  FUINotifyProc(Format(#13#10 + 'Adding Package %s...', [aPackage.Name]));

  VersionSHA := GetSelectedVersionSHA(aDispalyVersionName, aPackage, VersionName);

  RepoTree := FGHAPI.GetRepoTree(aPackage.Owner, aPackage.Repo, VersionSHA);

  for TreeNode in RepoTree do
    begin
      if TreeNode.FileType <> 'blob' then
        Continue;

      if aPackage.AllowPath(TreeNode.Path) then
        begin
          Blob := FGHAPI.GetRepoBlob(TreeNode.URL);

          NodePath := aPackage.ApplyMoves(TreeNode.Path);
          FilePath := SaveContent(PackagePath, NodePath, Blob.Content);
          Extension := TPath.GetExtension(FilePath);

          if (Extension = '.pas') and (aPackage.PackageType = ptSource) then
            GetActiveProject.AddFile(FilePath, True);
        end;
    end;

  AddedPackage := TPackage.Create(aPackage);
  AddedVersion.Name := VersionName;
  AddedVersion.SHA := VersionSHA;
  AddedPackage.InstalledVersion := AddedVersion;

  ProjectPackageList := GetProjectPackageList;
  ProjectPackageList.Add(AddedPackage);
  SavePackages(ProjectPackageList, GetProjectPackagesFilePath);

  GetActiveProject.Save(False, True);}

  FUINotifyProc(Format(#13#10 + 'Adding %s...', [aPackage.Name]));

  PackagePath := GetPackagePath(aPackage);
  AddPackageFiles(aDisplayVersionName, PackagePath, aPackage);

  FUINotifyProc('Success');
end;

procedure TDPMEngine.AddTemplate(const aDisplayVersionName: string; aPackage: TPackage);
var
  ActiveProject: IOTAProject;
  Extension: string;
  i: Integer;
  PackageFile: string;
  PackageFiles: TArray<string>;
  PackagePath: string;
  ProjectModuleInfo: IOTAModuleInfo;
begin
  PackagePath := FUIGetFolder;
  if PackagePath.IsEmpty then
    Exit;

  FUINotifyProc(Format(#13#10 + 'Adding %s...', [aPackage.Name]));

  PackageFiles := AddPackageFiles(aDisplayVersionName, PackagePath, aPackage);

  for PackageFile in PackageFiles do
    begin
      Extension := TPath.GetExtension(PackageFile);

      if Extension = '.dproj' then
        begin
          FUINotifyProc('Opening project...');
          OpenProject(PackageFile);
          Break;
        end;
    end;

  ActiveProject := GetActiveProject;
  for i := 0 to ActiveProject.GetModuleCount - 1 do
    begin
      ProjectModuleInfo := ActiveProject.GetModule(i) as IOTAModuleInfo;
      Extension := TPath.GetExtension(ProjectModuleInfo.FileName);
      if Extension = '.pas' then
        begin
          ProjectModuleInfo.OpenModule.Show;
          Break;
        end;
    end;    

  FUINotifyProc('Success');
end;

function TDPMEngine.IsProjectOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
end;

function TDPMEngine.SaveContent(const aVendorPath, aRepoPath,
  aContent: string): string;
var
  Bytes: TBytes;
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := aVendorPath;
  RepoPathParts := aRepoPath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := Result + '\' + RepoPathPart;

  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  FUINotifyProc('write ' + Result);

  WriteFile(Result, Bytes);
end;

procedure TDPMEngine.SavePackage(aPackage: TPackage; const aPath: string);
var
  Bytes: TBytes;
  jsnPackageObj: TJSONObject;
begin
  jsnPackageObj := aPackage.CreateJSON;
  try
    Bytes := TEncoding.ANSI.GetBytes(jsnPackageObj.ToJSON);

    WriteFile(aPath, Bytes);
  finally
    jsnPackageObj.Free;
  end;
end;

procedure TDPMEngine.SavePackages(aPackageList: TPackageList;
  const aPath: string);
var
  Bytes: TBytes;
  sJSONObj: string;
begin
  sJSONObj := GetPackagesJSONString(aPackageList);

  Bytes := TEncoding.ANSI.GetBytes(sJSONObj);

  WriteFile(aPath, Bytes);
end;

procedure TDPMEngine.WriteFile(const aFilePath: string; aBytes: TBytes);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aFilePath));

  FS := TFile.Create(aFilePath);
  try
    FS.Position := FS.Size;
    FS.Write(aBytes[0], Length(aBytes));
  finally
    FS.Free;
  end;
end;

{ TCompileNotifier }

procedure TCompileNotifier.ProjectCompileFinished(const Project: IOTAProject;
  Result: TOTACompileResult);
begin
end;

procedure TCompileNotifier.ProjectCompileStarted(const Project: IOTAProject;
  Mode: TOTACompileMode);
begin
  FDPMEngine.BuildBIN(TDirectory.GetParent(Project.ProjectOptions.TargetName));
end;

procedure TCompileNotifier.ProjectGroupCompileFinished(
  Result: TOTACompileResult);
begin
end;

procedure TCompileNotifier.ProjectGroupCompileStarted(Mode: TOTACompileMode);
begin
end;

end.
