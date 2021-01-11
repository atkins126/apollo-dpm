unit Apollo_DPM_Engine;

interface

uses
  Apollo_DPM_GitHubAPI,
  Apollo_DPM_Package,
  Apollo_DPM_Types,
  Apollo_DPM_Version,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  TDPMEngine = class
  private
    FGHAPI: TGHAPI;
    FPrivatePackages: TPrivatePackageList;
    FProjectPackages: TDependentPackageList;
    FUINotifyProc: TUINotifyProc;
    FVersionCacheList: TVersionCacheList;
    function DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
    function GetActiveProject: IOTAProject;
    function GetActiveProjectPath: string;
    function GetApolloMenuItem: TMenuItem;
    function GetIDEMainMenu: TMainMenu;
    function GetDependentPackage(aPackage: TPackage): TDependentPackage;
    function GetInitialPackage(aDependentPackage: TDependentPackage): TInitialPackage;
    function GetInstallPackageHandle(aDependentPackage: TDependentPackage;
      aVersion: TVersion): TPackageHandle;
    function GetPackagePath(aPackage: TPackage): string;
    function GetProjectPackagesPath: string;
    function GetPrivatePackagesFolderPath: string;
    function GetVendorsPath: string;
    function GetVersionCacheList: TVersionCacheList;
    function GetTextFromFile(const aPath: string): string;
    function IsProjectOpened: Boolean;
    function LoadDependencies(aInitialPackage: TInitialPackage; aVersion: TVersion): TDependentPackageList; overload;
    function LoadDependencies(aDependentPackage: TDependentPackage): TDependentPackageList; overload;
    function LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
    function PostProcessPackageHandles(const aPackageHandles: TPackageHandles): TPackageHandles;
    function SaveAsPrivatePackage(aPackage: TInitialPackage): string;
    function SaveContent(const aPackagePath, aSourcePath, aContent: string): string;
    function SyncVersionCache(const aPackageID: string; aVersion: TVersion): TVersion;
    procedure AddApolloMenuItem;
    procedure AddDPMMenuItem;
    procedure AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
    procedure BuildMenu;
    procedure DeletePackagePath(aPackage: TPackage);
    procedure DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion);
    procedure DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
      aResult: TDependentPackageList); overload;
    procedure DoLoadDependencies(aDependentPackage: TDependentPackage; aResult: TDependentPackageList); overload;
    procedure DoUninstall(aDependentPackage: TDependentPackage);
    procedure DPMMenuItemClick(Sender: TObject);
    procedure FreePackageLists;
    procedure FreeVersionCacheList;
    procedure LoadRepoVersions(aPackage: TPackage);
    procedure SaveProjectPackages;
    procedure WriteFile(const aPath: string; const aBytes: TBytes);
  public
    function AreVersionsLoaded(const aPackageID: string): Boolean;
    function AllowAction(const aFrameActionType: TFrameActionType;
      aPackage: TPackage; aVersion: TVersion): Boolean;
    function GetPrivatePackages: TPrivatePackageList;
    function GetProjectPackages: TDependentPackageList;
    function GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
    function Install(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
    function LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName, aError: string): Boolean;
    function Uninstall(aPackage: TPackage): TPackageHandles;
    function Update(aPackage: TPackage; aVersion: TVersion): TPackageHandles;
    procedure AddNewPrivatePackage(aPackage: TInitialPackage);
    procedure UpdatePrivatePackage(aPackage: TPrivatePackage);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Apollo_DPM_Consts,
  Apollo_DPM_Form,
  Apollo_DPM_Validation,
  System.Classes,
  System.IOUtils,
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

procedure TDPMEngine.AddNewPrivatePackage(aPackage: TInitialPackage);
var
  Package: TPrivatePackage;
  Path: string;
begin
  Path := SaveAsPrivatePackage(aPackage);

  Package := TPrivatePackage.Create(GetTextFromFile(Path));
  Package.FilePath := Path;

  GetPrivatePackages.Add(Package);
end;

procedure TDPMEngine.AddPackageFiles(aInitialPackage: TInitialPackage; aVersion: TVersion);
var
  Blob: TBlob;
  NodePath: string;
  TreeNode: TTreeNode;
begin
  for TreeNode in aVersion.RepoTree do
  begin
    if TreeNode.FileType <> 'blob' then
      Continue;

    if aInitialPackage.AllowPath(TreeNode.Path) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);

      NodePath := aInitialPackage.ApplyPathMoves(TreeNode.Path);
      SaveContent(GetPackagePath(aInitialPackage), NodePath, Blob.Content);
    end;
  end;
end;

function TDPMEngine.AllowAction(const aFrameActionType: TFrameActionType;
  aPackage: TPackage; aVersion: TVersion): Boolean;
var
  DependentPackage: TDependentPackage;
  InitialPackage: TInitialPackage;
begin
  Result := False;

  if aPackage is TInitialPackage then
  begin
    InitialPackage := aPackage as TInitialPackage;

    case aFrameActionType of
      fatInstall:
        Result := IsProjectOpened and
          Assigned(aVersion) and
          (not InitialPackage.IsInstalled);

      fatUpdate:
        Result := Assigned(aVersion) and
          InitialPackage.IsInstalled and
          (InitialPackage.DependentPackage.Version.SHA <> aVersion.SHA);

      fatUninstall:
        begin
          Result := IsProjectOpened and
            Assigned(aVersion) and
            InitialPackage.IsInstalled and
            (InitialPackage.DependentPackage.Version.SHA = aVersion.SHA);
        end;

      fatEditPackage:
        Result := True;
    end;
  end
  else
  if aPackage is TDependentPackage then
  begin
    DependentPackage := aPackage as TDependentPackage;

    case aFrameActionType of
      fatInstall:
        Result := False;

      fatUpdate:
        Result := Assigned(aVersion) and
          (DependentPackage.Version.SHA <> aVersion.SHA);

      fatUninstall:
        Result := IsProjectOpened and
          Assigned(aVersion) and
          (DependentPackage.Version.SHA = aVersion.SHA);

      fatEditPackage:
        Result := False;
    end;
  end;
end;

function TDPMEngine.AreVersionsLoaded(const aPackageID: string): Boolean;
begin
  Result := GetVersionCacheList.ContainsLoadedPackageID(aPackageID);
end;

procedure TDPMEngine.BuildMenu;
begin
  if GetApolloMenuItem = nil then
    AddApolloMenuItem;

  AddDPMMenuItem;
end;

constructor TDPMEngine.Create;
begin
  FGHAPI := TGHAPI.Create;

  BuildMenu;

  Validation := TValidation.Create(Self);
end;

function TDPMEngine.DefineVersion(aPackage: TPackage; aVersion: TVersion): TVersion;
var
  Versions: TArray<TVersion>;
begin
  if not aVersion.SHA.IsEmpty then
    Exit(aVersion);

  if aVersion.Name = cStrLatestVersionOrCommit then
  begin
    Versions := GetVersions(aPackage);
    if Length(Versions) > 0 then
      Exit(Versions[0]);
  end;

  Result := TVersion.Create;
  Result.Name := '';
  Result.SHA := FGHAPI.GetMasterBranchSHA(aPackage.RepoOwner, aPackage.RepoName);
  Result := SyncVersionCache(aPackage.ID, Result);
end;

procedure TDPMEngine.DeletePackagePath(aPackage: TPackage);
var
  Path: string;
begin
  Path := GetPackagePath(aPackage);

  FUINotifyProc('Deleting ' + Path);

  TDirectory.Delete(Path, True);

  if Length(TDirectory.GetDirectories(GetVendorsPath, '*', TSearchOption.soTopDirectoryOnly)) = 0 then
    TDirectory.Delete(GetVendorsPath);
end;

destructor TDPMEngine.Destroy;
begin
  Validation.Free;
  FGHAPI.Free;
  FreePackageLists;
  FreeVersionCacheList;

  if GetApolloMenuItem <> nil then
    GetIDEMainMenu.Items.Remove(GetApolloMenuItem);

  inherited;
end;

procedure TDPMEngine.DoInstall(aInitialPackage: TInitialPackage; aVersion: TVersion);
var
  DependentPackage: TDependentPackage;
begin
  FUINotifyProc(Format(#13#10 + 'Installing %s %s', [aInitialPackage.Name, aVersion.DisplayName]));

  DependentPackage := TDependentPackage.CreateByInitial(aInitialPackage);
  DependentPackage.Version := aVersion;

  AddPackageFiles(aInitialPackage, aVersion);

  GetProjectPackages.Add(DependentPackage);
end;

procedure TDPMEngine.DoLoadDependencies(aDependentPackage: TDependentPackage; aResult: TDependentPackageList);
var
  DependentPackage: TDependentPackage;
  ID: string;
begin
  for ID in aDependentPackage.Version.Dependencies do
    if not GetProjectPackages.DoUseDependence(ID, aDependentPackage.ID) then
    begin
      DependentPackage := GetProjectPackages.GetByID(ID);

      if Assigned(DependentPackage) then
      begin
        aResult.Add(DependentPackage);
        DoLoadDependencies(DependentPackage, aResult);
      end;
    end;
end;

procedure TDPMEngine.DoUninstall(aDependentPackage: TDependentPackage);
var
  InitialPackage: TInitialPackage;
begin
  FUINotifyProc(Format(#13#10 + 'Uninstalling %s %s', [aDependentPackage.Name,
    aDependentPackage.Version.DisplayName]));

  DeletePackagePath(aDependentPackage);

  InitialPackage := GetInitialPackage(aDependentPackage);
  if Assigned(InitialPackage) then
    InitialPackage.DependentPackage := nil;

  GetProjectPackages.RemoveByID(aDependentPackage.ID);
end;

procedure TDPMEngine.DoLoadDependencies(aDependentPackage: TDependentPackage; aVersion: TVersion;
  aResult: TDependentPackageList);
var
  Blob: TBlob;
  i: Integer;
  Package: TDependentPackage;
  PackageList: TDependentPackageList;
  sJSON: string;
  TreeNode: TTreeNode;
begin
  aVersion.RepoTree := LoadRepoTree(aDependentPackage, aVersion);
  aVersion.Dependencies := [];

  for TreeNode in aVersion.RepoTree do
    if TreeNode.Path.EndsWith(cProjectPackagesPath) then
    begin
      Blob := FGHAPI.GetRepoBlob(TreeNode.URL);
      sJSON := TNetEncoding.Base64.Decode(Blob.Content);

      PackageList := TDependentPackageList.Create(sJSON, SyncVersionCache);
      try
        for i := PackageList.Count - 1 downto 0 do
        begin
          Package := PackageList.ExtractAt(i);
          aResult.Add(Package);
          aVersion.Dependencies := aVersion.Dependencies + [Package.ID];

          DoLoadDependencies(Package, Package.Version, aResult);
        end;
      finally
        PackageList.Free;
      end;
    end;
end;

procedure TDPMEngine.DPMMenuItemClick(Sender: TObject);
begin
  DPMForm := TDPMForm.Create(Self);
  try
    FUINotifyProc := DPMForm.NotifyObserver;
    DPMForm.ShowModal;
  finally
    DPMForm.Free;
    FreePackageLists;
  end;
end;

function TDPMEngine.GetInitialPackage(
  aDependentPackage: TDependentPackage): TInitialPackage;
begin
  Result := GetPrivatePackages.GetByID(aDependentPackage.ID);

  if Assigned(Result) then
    Exit(Result);
end;

procedure TDPMEngine.FreePackageLists;
begin
  if Assigned(FPrivatePackages) then
    FreeAndNil(FPrivatePackages);
  if Assigned(FProjectPackages) then
    FreeAndNil(FProjectPackages);
end;

procedure TDPMEngine.FreeVersionCacheList;
begin
  if Assigned(FVersionCacheList) then
    FreeAndNil(FVersionCacheList);
end;

function TDPMEngine.GetActiveProject: IOTAProject;
var
  i: Integer;
  Module: IOTAModule;
  ModuleServices: IOTAModuleServices;
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

function TDPMEngine.GetDependentPackage(aPackage: TPackage): TDependentPackage;
begin
  if aPackage is TDependentPackage then
    Result := aPackage as TDependentPackage
  else
  if aPackage is TInitialPackage then
    Result := (aPackage as TInitialPackage).DependentPackage
  else
    raise Exception.Create('Uninstall: unknown package type');
end;

function TDPMEngine.GetIDEMainMenu: TMainMenu;
begin
  Result := (BorlandIDEServices as INTAServices).MainMenu;
end;

function TDPMEngine.GetInstallPackageHandle(aDependentPackage: TDependentPackage;
  aVersion: TVersion): TPackageHandle;
var
  InitialPackage: TInitialPackage;
  NeedToFree: Boolean;
begin
  NeedToFree := False;

  InitialPackage := GetInitialPackage(aDependentPackage);

  if not Assigned(InitialPackage) then
  begin
    InitialPackage := TInitialPackage.Create;
    InitialPackage.Assign(aDependentPackage);
    NeedToFree := True;
  end;
  Result := TPackageHandle.Create(paInstall, InitialPackage, aVersion, NeedToFree);
end;

function TDPMEngine.GetPackagePath(aPackage: TPackage): string;
begin
  Result := TPath.Combine(GetVendorsPath, aPackage.Name);
end;

function TDPMEngine.GetPrivatePackages: TPrivatePackageList;
var
  DependentPackage: TDependentPackage;
  FileArr: TArray<string>;
  FileItem: string;
  PrivatePackage: TPrivatePackage;
  PrivatePackageFile: TPrivatePackageFile;
  PrivatePackageFiles: TArray<TPrivatePackageFile>;
begin
  if FPrivatePackages = nil then
  begin
    if TDirectory.Exists(GetPrivatePackagesFolderPath) then
    begin
      FileArr := TDirectory.GetFiles(GetPrivatePackagesFolderPath, '*.json');
      PrivatePackageFiles := [];
      for FileItem in FileArr do
      begin
        PrivatePackageFile.Path := FileItem;
        PrivatePackageFile.JSONString := GetTextFromFile(FileItem);

        PrivatePackageFiles := PrivatePackageFiles + [PrivatePackageFile];
      end;

      if Length(PrivatePackageFiles) > 0 then
        FPrivatePackages := TPrivatePackageList.Create(PrivatePackageFiles);

      for PrivatePackage in FPrivatePackages do
      begin
        DependentPackage := GetProjectPackages.GetByID(PrivatePackage.ID);
        if Assigned(DependentPackage) then
          PrivatePackage.DependentPackage := DependentPackage;
      end;
    end;
  end;

  if not Assigned(FPrivatePackages) then
    FPrivatePackages := TPrivatePackageList.Create([]);
  Result := FPrivatePackages;
end;

function TDPMEngine.GetPrivatePackagesFolderPath: string;
begin
  Result := TPath.Combine(TPath.GetPublicPath, cPrivatePackagesFolderPath);
end;

function TDPMEngine.GetProjectPackages: TDependentPackageList;
var
  sJSON: string;
begin
  if not Assigned(FProjectPackages) then
  begin
    if TFile.Exists(GetProjectPackagesPath) then
    begin
      sJSON := TFile.ReadAllText(GetProjectPackagesPath, TEncoding.ANSI);
      FProjectPackages := TDependentPackageList.Create(sJSON, SyncVersionCache);
    end
    else
      FProjectPackages := TDependentPackageList.Create;
  end;

  Result := FProjectPackages;
end;

function TDPMEngine.GetProjectPackagesPath: string;
begin
  if IsProjectOpened then
    Result := TPath.Combine(GetActiveProjectPath, cProjectPackagesPath)
  else
    Result := '';
end;

function TDPMEngine.GetTextFromFile(const aPath: string): string;
begin
  Result := TFile.ReadAllText(aPath, TEncoding.ANSI);
end;

function TDPMEngine.GetVendorsPath: string;
begin
  Result := TPath.Combine(TDirectory.GetParent(GetActiveProjectPath), 'Vendors');
end;

function TDPMEngine.GetVersionCacheList: TVersionCacheList;
begin
  if not Assigned(FVersionCacheList) then
    FVersionCacheList := TVersionCacheList.Create;

  Result := FVersionCacheList;
end;

function TDPMEngine.GetVersions(aPackage: TPackage; aCachedOnly: Boolean = False): TArray<TVersion>;
begin
  if (not aCachedOnly) and (not AreVersionsLoaded(aPackage.ID)) then
    LoadRepoVersions(aPackage);

  Result := GetVersionCacheList.GetByPackageID(aPackage.ID);
end;

function TDPMEngine.Install(aInitialPackage: TInitialPackage; aVersion: TVersion): TPackageHandles;
var
  Dependencies: TDependentPackageList;
  Dependency: TDependentPackage;
  PackageHandle: TPackageHandle;
  Version: TVersion;
begin
  Version := DefineVersion(aInitialPackage, aVersion);
  Result := [TPackageHandle.Create(paInstall, aInitialPackage, Version)];

  Dependencies := LoadDependencies(aInitialPackage, Version);
  try
    for Dependency in Dependencies do
      Result := Result + [GetInstallPackageHandle(Dependency, Dependency.Version)];
  finally
    Dependencies.Free;
  end;

  for PackageHandle in Result do
    DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version);

  Result := PostProcessPackageHandles(Result);

  SaveProjectPackages;

  FUINotifyProc(#13#10'Success');
end;

function TDPMEngine.IsProjectOpened: Boolean;
begin
  Result := GetActiveProject <> nil;
end;

function TDPMEngine.LoadDependencies(aInitialPackage: TInitialPackage; aVersion: TVersion): TDependentPackageList;
var
  DependentPackage: TDependentPackage;
begin
  Result := TDependentPackageList.Create;

  DependentPackage := TDependentPackage.CreateByInitial(aInitialPackage, False);
  try
    DoLoadDependencies(DependentPackage, aVersion, Result);
  finally
    FreeAndNil(DependentPackage);
  end;
end;

function TDPMEngine.LoadDependencies(
  aDependentPackage: TDependentPackage): TDependentPackageList;
begin
  Result := TDependentPackageList.Create(False);
  DoLoadDependencies(aDependentPackage, Result);
end;

function TDPMEngine.LoadRepoData(const aRepoURL: string; out aRepoOwner, aRepoName,
  aError: string): Boolean;
var
  RepoURL: string;
  SHA: string;
  URLWords: TArray<string>;
begin
  Result := False;
  RepoURL := aRepoURL;
  aRepoOwner := '';
  aRepoName := '';
  aError := '';

  if RepoURL.Contains('://') then
    RepoURL := RepoURL.Substring(RepoURL.IndexOf('://') + 3, RepoURL.Length);
  URLWords := RepoURL.Split(['/']);

  if (not (Length(URLWords) >= 3)) or
   ((Length(URLWords) > 0) and (URLWords[0].ToLower <> 'github.com'))
  then
  begin
    aError := cStrTheGitHubRepositoryUrlIsInvalid;
    Exit;
  end;

  try
    SHA := FGHAPI.GetMasterBranchSHA(URLWords[1], URLWords[2]);
  except
    aError := cStrCantLoadTheRepositoryURL;
    Exit;
  end;

  if SHA.IsEmpty then
    Exit;

  Result := True;
  aRepoOwner := URLWords[1];
  aRepoName := URLWords[2];
end;

function TDPMEngine.LoadRepoTree(aPackage: TPackage; aVersion: TVersion): TTree;
begin
  if aVersion.RepoTreeLoaded then
    Exit(aVersion.RepoTree);

  Result := FGHAPI.GetRepoTree(aPackage.RepoOwner, aPackage.RepoName,
    aVersion.SHA);

  aVersion.RepoTreeLoaded := True;
end;

procedure TDPMEngine.LoadRepoVersions(aPackage: TPackage);
var
  Tag:  TTag;
  Tags: TArray<TTag>;
  Version: TVersion;
begin
  Tags := FGHAPI.GetRepoTags(aPackage.RepoOwner, aPackage.RepoName);

  for Tag in Tags do
  begin
    Version := TVersion.Create;

    Version.Name := Tag.Name;
    Version.SHA := Tag.SHA;

    SyncVersionCache(aPackage.ID, Version);
  end;

  GetVersionCacheList.AddLoadedPackageID(aPackage.ID);
end;

function TDPMEngine.PostProcessPackageHandles(
  const aPackageHandles: TPackageHandles): TPackageHandles;
var
  i: Integer;
  PackageHandle: TPackageHandle;
begin
  Result := [];

  for i := High(aPackageHandles) downto 0 do
  begin
    PackageHandle := aPackageHandles[i];

    if PackageHandle.NeedToFree then
      PackageHandle.Package.Free;
    PackageHandle.Package := nil;

    if (PackageHandle.PackageAction = paUninstall) and
       aPackageHandles.ContainsInstallHandle(PackageHandle.PackageID)
    then
      //do nothing
    else
      Result := Result + [PackageHandle];
  end;
end;

function TDPMEngine.SaveAsPrivatePackage(aPackage: TInitialPackage): string;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(aPackage.GetJSONString);
  Result := TPath.Combine(GetPrivatePackagesFolderPath, aPackage.Name + '.json');

  WriteFile(Result, Bytes);
end;

function TDPMEngine.SaveContent(const aPackagePath, aSourcePath,
  aContent: string): string;
var
  Bytes: TBytes;
  RepoPathPart: string;
  RepoPathParts: TArray<string>;
begin
  Result := aPackagePath;
  RepoPathParts := aSourcePath.Split(['/']);

  for RepoPathPart in RepoPathParts do
    Result := Result + '\' + RepoPathPart;

  Bytes := TNetEncoding.Base64.DecodeStringToBytes(aContent);

  WriteFile(Result, Bytes);

  FUINotifyProc('Writing ' + Result);
end;

procedure TDPMEngine.SaveProjectPackages;
var
  Bytes: TBytes;
begin
  if GetProjectPackages.Count = 0 then
    TFile.Delete(GetProjectPackagesPath)
  else
  begin
    Bytes := TEncoding.ANSI.GetBytes(GetProjectPackages.GetJSONString);
    WriteFile(GetProjectPackagesPath, Bytes);
  end;
end;

function TDPMEngine.Uninstall(aPackage: TPackage): TPackageHandles;
var
  Dependency: TDependentPackage;
  Dependencies: TDependentPackageList;
  DependentPackage: TDependentPackage;
  PackageHandle: TPackageHandle;
begin
  DependentPackage := GetDependentPackage(aPackage);
  Result := [TPackageHandle.Create(paUninstall, DependentPackage, nil)];

  Dependencies := LoadDependencies(DependentPackage);
  try
    for Dependency in Dependencies do
      Result := Result + [TPackageHandle.Create(paUninstall, Dependency, nil)];
  finally
    Dependencies.Free;
  end;

  for PackageHandle in Result do
  begin
    DoUninstall(PackageHandle.Package as TDependentPackage);
  end;

  SaveProjectPackages;

  FUINotifyProc(#13#10'Success');
end;

function TDPMEngine.Update(aPackage: TPackage; aVersion: TVersion): TPackageHandles;
var
  DependentPackage: TDependentPackage;
  ExistPackage: TDependentPackage;
  NewDependencies: TDependentPackageList;
  NewDependency: TDependentPackage;
  OldDependencies: TDependentPackageList;
  OldDependency: TDependentPackage;
  PackageHandle: TPackageHandle;
  Version: TVersion;
begin
  Version := DefineVersion(aPackage, aVersion);

  DependentPackage := GetDependentPackage(aPackage);
  if DependentPackage.Version.SHA = Version.SHA then
  begin
    FUINotifyProc(Format(#13#10 + 'Package %s %s already up to date.', [aPackage.Name, Version.DisplayName]));
    Result := [TPackageHandle.Create(paInstall, aPackage, Version)];
    Exit;
  end;

  Result := [TPackageHandle.Create(paUninstall, DependentPackage, nil)];
  Result := Result + [GetInstallPackageHandle(DependentPackage, Version)];

  OldDependencies := LoadDependencies(DependentPackage);
  NewDependencies := LoadDependencies(Result.GetFirstInstallPackage, Version);
  try
    for OldDependency in OldDependencies do
    begin
      NewDependency := NewDependencies.GetByID(OldDependency.ID);
      if not Assigned(NewDependency) or (NewDependency.Version.SHA <> OldDependency.Version.SHA) then
        Result := Result + [TPackageHandle.Create(paUninstall, OldDependency, nil)];
    end;

    for NewDependency in NewDependencies do
    begin
      ExistPackage := GetProjectPackages.GetByID(NewDependency.ID);
      if not Assigned(ExistPackage) or (NewDependency.Version.SHA <> ExistPackage.Version.SHA) then
        Result := Result + [GetInstallPackageHandle(NewDependency, NewDependency.Version)];
    end;

    for PackageHandle in Result do
      if PackageHandle.PackageAction = paUninstall then
        DoUninstall(PackageHandle.Package as TDependentPackage);

    for PackageHandle in Result do
      if PackageHandle.PackageAction = paInstall then
        DoInstall(PackageHandle.Package as TInitialPackage, PackageHandle.Version);

    Result := PostProcessPackageHandles(Result);

    SaveProjectPackages;

    FUINotifyProc(#13#10'Success');
  finally
    OldDependencies.Free;
    NewDependencies.Free;
  end;
end;

procedure TDPMEngine.UpdatePrivatePackage(aPackage: TPrivatePackage);
begin
  TFile.Delete(aPackage.FilePath);
  aPackage.FilePath := SaveAsPrivatePackage(aPackage);
end;

function TDPMEngine.SyncVersionCache(const aPackageID: string; aVersion: TVersion): TVersion;
begin
  Result := GetVersionCacheList.SyncVersion(aPackageID, aVersion);
end;

procedure TDPMEngine.WriteFile(const aPath: string; const aBytes: TBytes);
var
  FS: TFileStream;
begin
  ForceDirectories(TDirectory.GetParent(aPath));

  FS := TFile.Create(aPath);
  try
    FS.Position := FS.Size;
    FS.Write(aBytes[0], Length(aBytes));
  finally
    FS.Free;
  end;
end;

end.
