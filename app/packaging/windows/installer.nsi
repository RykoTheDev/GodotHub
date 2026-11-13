Unicode true
ManifestDPIAware true
SetCompressor /SOLID lzma
RequestExecutionLevel user

!ifndef VERSION
  !error "pass /DVERSION=x.y.z"
!endif
!ifndef SOURCE_DIR
  !error "pass /DSOURCE_DIR=<flutter Release folder>"
!endif
!ifndef OUTFILE
  !error "pass /DOUTFILE=<setup.exe path>"
!endif
!ifndef IDENTIFIER
  !error "pass /DIDENTIFIER=<channel identifier>"
!endif
!ifndef DISPLAY_NAME
  !error "pass /DDISPLAY_NAME=<channel display name>"
!endif
!ifndef EXE_NAME
  !error "pass /DEXE_NAME=<binary name>.exe"
!endif
!ifndef ICON
  !error "pass /DICON=<app_icon.ico>"
!endif
!ifndef PLUGIN_DIR
  !error "pass /DPLUGIN_DIR=<folder with ApplicationID.dll>"
!endif
!ifndef LAUNCHER
  !error "pass /DLAUNCHER=<godothub-launcher.exe>"
!endif

!addplugindir /x86-unicode "${PLUGIN_DIR}"

!include "MUI2.nsh"
!include "FileFunc.nsh"

!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${IDENTIFIER}"
!define APP_KEY "Software\Ryko\${IDENTIFIER}"
!define SHORTCUT "$SMPROGRAMS\${DISPLAY_NAME}.lnk"

Name "${DISPLAY_NAME}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\${DISPLAY_NAME}"
BrandingText "${DISPLAY_NAME} ${VERSION}"
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${DISPLAY_NAME}"
VIAddVersionKey "CompanyName" "Ryko"
VIAddVersionKey "LegalCopyright" "Ryko"
VIAddVersionKey "FileDescription" "${DISPLAY_NAME} Setup"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"

!define MUI_ICON "${ICON}"
!define MUI_UNICON "${ICON}"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE_NAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${DISPLAY_NAME}"

Var Passive
Var Restart

!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipIfPassive
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipIfPassive
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!macro RequireOwnFolder
  ${GetFileName} "$INSTDIR" $0
  StrCmp $0 "${DISPLAY_NAME}" +3 0
    MessageBox MB_ICONSTOP "Refusing to use $INSTDIR: ${DISPLAY_NAME} only installs into its own folder."
    Abort
!macroend

!macro WaitForAppToClose
  StrCpy $1 0
  retry:
    ClearErrors
    IfFileExists "$INSTDIR\${EXE_NAME}" 0 done
    Rename "$INSTDIR\${EXE_NAME}" "$INSTDIR\${EXE_NAME}.closing"
    IfErrors 0 restore
    IntOp $1 $1 + 1
    IntCmp $1 20 ask 0 ask
    Sleep 500
    Goto retry
  ask:
    IfSilent abort
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Close ${DISPLAY_NAME} and click Retry." IDRETRY retry
  abort:
    Abort
  restore:
    Rename "$INSTDIR\${EXE_NAME}.closing" "$INSTDIR\${EXE_NAME}"
  done:
!macroend

Function SkipIfPassive
  StrCmp $Passive 1 0 +2
    Abort
FunctionEnd

Function .onInit
  !insertmacro RequireOwnFolder
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 "/P" $R1
  IfErrors +2 0
    StrCpy $Passive 1
  ClearErrors
  ${GetOptions} $R0 "/R" $R1
  IfErrors +2 0
    StrCpy $Restart 1
FunctionEnd

Function .onInstSuccess
  StrCmp $Restart 1 0 +2
    Exec '"$INSTDIR\${EXE_NAME}"'
FunctionEnd

Section "Install"
  StrCmp $Passive 1 0 +2
    SetAutoClose true
  !insertmacro RequireOwnFolder
  !insertmacro WaitForAppToClose
  RMDir /r "$INSTDIR\data"
  Delete "$INSTDIR\*.dll"
  RMDir /r "$INSTDIR\app-${VERSION}"
  SetOutPath "$INSTDIR\app-${VERSION}"
  File /r "${SOURCE_DIR}\*.*"
  SetOutPath "$INSTDIR"
  File "/oname=${EXE_NAME}" "${LAUNCHER}"
  File "/oname=app.ico" "${ICON}"
  FileOpen $0 "$INSTDIR\launcher.json" w
  FileWrite $0 '{"current": "${VERSION}"}'
  FileClose $0
  WriteUninstaller "$INSTDIR\uninstall.exe"

  CreateShortcut "${SHORTCUT}" "$INSTDIR\${EXE_NAME}" "" "$INSTDIR\app.ico" 0
  ApplicationID::Set "${SHORTCUT}" "${IDENTIFIER}"
  Pop $0

  WriteRegStr HKCU "${APP_KEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "${APP_KEY}" "Version" "${VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${DISPLAY_NAME}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "Ryko"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\app.ico"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKCU "${UNINSTALL_KEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" "$0"
SectionEnd

Function un.onInit
  ${GetFileName} "$INSTDIR" $0
  StrCmp $0 "${DISPLAY_NAME}" +3 0
    MessageBox MB_ICONSTOP "Refusing to uninstall from $INSTDIR."
    Abort
FunctionEnd

Section "Uninstall"
  !insertmacro WaitForAppToClose
  Delete "${SHORTCUT}"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  DeleteRegKey HKCU "${APP_KEY}"
  DeleteRegKey /ifempty HKCU "Software\Ryko"
SectionEnd
