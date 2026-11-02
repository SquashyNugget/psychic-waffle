#!/usr/bin/env python3
"""Generate a standalone Xcode project from this repository (Python stdlib only).

The included project.yml can alternatively be used with XcodeGen. This generator
keeps the downloadable ZIP self-contained and immediately openable in Xcode.
"""
from __future__ import annotations
import hashlib
import html
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'BadmintonCourtManager.xcodeproj'
PROJECT.mkdir(exist_ok=True)
OBJS = {}

def uid(name):
    return hashlib.sha1(('badminton-court-manager:' + name).encode()).hexdigest().upper()[:24]

def add(key_name, isa, **props):
    key = uid(key_name)
    assert key not in OBJS, key_name
    OBJS[key] = {'isa': isa, **props}
    return key

class Ref(str):
    pass

def ref(s): return Ref(s)

def q(s):
    if isinstance(s, Ref): return str(s)
    if re.fullmatch(r'[A-Za-z0-9_$./+\-]+', str(s)):
        return str(s)
    return '"' + str(s).replace('\\','\\\\').replace('"','\\"').replace('\n','\\n') + '"'

def fmt(value, indent=0):
    sp = '\t' * indent
    if isinstance(value, dict):
        if not value: return '{}'
        result = ['{']
        for k,v in value.items():
            result.append(sp + '\t' + q(k) + ' = ' + fmt(v, indent + 1) + ';')
        result.append(sp + '}')
        return '\n'.join(result)
    if isinstance(value, (tuple,list)):
        if not value: return '()'
        return '(\n'+'\n'.join(sp+'\t'+fmt(x, indent+1)+',' for x in value)+'\n'+sp+')'
    return q(value)

app_files = sorted(list((ROOT / 'App').glob('*.swift')) +
                   list((ROOT / 'Core').glob('*.swift')) +
                   list((ROOT / 'Services').glob('*.swift')) +
                   list((ROOT / 'UI').glob('*.swift')) +
                   list((ROOT / 'Shared').glob('*.swift')))
widget_files = sorted(list((ROOT / 'WidgetExtension').glob('*.swift')) +
                      list((ROOT / 'Shared').glob('*.swift')))

app_product = add('product-app','PBXFileReference',
                  explicitFileType='wrapper.application', includeInIndex='0',
                  path='BadmintonCourtManager.app', sourceTree='BUILT_PRODUCTS_DIR')
widget_product = add('product-widget','PBXFileReference',
                     explicitFileType='wrapper.app-extension', includeInIndex='0',
                     path='CourtLiveActivityExtension.appex', sourceTree='BUILT_PRODUCTS_DIR')

file_refs = {}
group_refs = []
for folder in ['App','Core','Services','UI','Shared','WidgetExtension','Resources']:
    children = []
    paths = []
    if folder == 'Resources':
        paths = [ROOT/'Resources'/'Assets.xcassets']
    else:
        paths = sorted((ROOT/folder).glob('*.swift'))
        if folder in ['App','WidgetExtension']:
            paths.append(ROOT/folder/'Info.plist')
    for p in paths:
        rel = p.relative_to(ROOT).as_posix()
        if p.suffix == '.swift': type_ = 'sourcecode.swift'
        elif p.suffix == '.plist': type_ = 'text.plist.xml'
        elif p.suffix == '.xcassets': type_ = 'folder.assetcatalog'
        else: type_ = 'text'
        key = add('file-'+rel,'PBXFileReference',lastKnownFileType=type_,
                  path=p.name, sourceTree='<group>')
        file_refs[rel] = key
        children.append(ref(key))
    grp = add('group-'+folder,'PBXGroup',children=children,path=folder,sourceTree='<group>')
    group_refs.append(ref(grp))

products = add('group-products','PBXGroup',children=[ref(app_product),ref(widget_product)],
               name='Products',sourceTree='<group>')
main_group = add('main-group','PBXGroup',children=group_refs+[ref(products)],sourceTree='<group>')

app_builds = []
for p in app_files:
    rel = p.relative_to(ROOT).as_posix()
    app_builds.append(ref(add('app-build-'+rel,'PBXBuildFile',fileRef=ref(file_refs[rel]))))
widget_builds = []
for p in widget_files:
    rel = p.relative_to(ROOT).as_posix()
    widget_builds.append(ref(add('widget-build-'+rel,'PBXBuildFile',fileRef=ref(file_refs[rel]))))
assets_build = add('app-asset-build','PBXBuildFile',fileRef=ref(file_refs['Resources/Assets.xcassets']))
embed_build = add('embed-widget-build','PBXBuildFile',fileRef=ref(widget_product),
                  settings={'ATTRIBUTES':['RemoveHeadersOnCopy']})

app_sources = add('app-sources','PBXSourcesBuildPhase',buildActionMask='2147483647', files=app_builds, runOnlyForDeploymentPostprocessing='0')
widget_sources = add('widget-sources','PBXSourcesBuildPhase',buildActionMask='2147483647',files=widget_builds,runOnlyForDeploymentPostprocessing='0')
app_resources = add('app-resources','PBXResourcesBuildPhase',buildActionMask='2147483647',files=[ref(assets_build)],runOnlyForDeploymentPostprocessing='0')
widget_resources = add('widget-resources','PBXResourcesBuildPhase',buildActionMask='2147483647',files=[],runOnlyForDeploymentPostprocessing='0')
app_frameworks = add('app-frameworks','PBXFrameworksBuildPhase',buildActionMask='2147483647',files=[],runOnlyForDeploymentPostprocessing='0')
widget_frameworks = add('widget-frameworks','PBXFrameworksBuildPhase',buildActionMask='2147483647',files=[],runOnlyForDeploymentPostprocessing='0')
embed_phase = add('embed-extensions','PBXCopyFilesBuildPhase',buildActionMask='2147483647',dstPath='',dstSubfolderSpec='13',files=[ref(embed_build)],name='Embed App Extensions',runOnlyForDeploymentPostprocessing='0')

app_target_id = uid('target-app')
widget_target_id = uid('target-widget')
proxy = add('target-proxy','PBXContainerItemProxy',containerPortal=ref(uid('project')),
            proxyType='1',remoteGlobalIDString=ref(widget_target_id),remoteInfo='CourtLiveActivityExtension')
dep = add('target-dependency','PBXTargetDependency',target=ref(widget_target_id),targetProxy=ref(proxy))

project_debug = {
    'ALWAYS_SEARCH_USER_PATHS':'NO','CLANG_ENABLE_MODULES':'YES',
    'CODE_SIGN_STYLE':'Automatic',
    'CURRENT_PROJECT_VERSION':'1','MARKETING_VERSION':'1.0',
    'IPHONEOS_DEPLOYMENT_TARGET':'17.0',
    'SWIFT_VERSION':'5.0','TARGETED_DEVICE_FAMILY':'1,2',
    'SDKROOT':'iphoneos',
    'ENABLE_USER_SCRIPT_SANDBOXING':'NO',
    'DEBUG_INFORMATION_FORMAT':'dwarf',
    'GCC_OPTIMIZATION_LEVEL':'0',
    'SWIFT_OPTIMIZATION_LEVEL':'-Onone',
}
project_release = {**project_debug,'DEBUG_INFORMATION_FORMAT':'dwarf-with-dsym',
                   'SWIFT_OPTIMIZATION_LEVEL':'-O', 'SWIFT_COMPILATION_MODE':'wholemodule'}

def config(settings,name_prefix,configuration):
    return add('config-'+name_prefix+'-'+configuration,'XCBuildConfiguration',name=configuration,
               buildSettings=settings)

def conf_list(prefix, configs):
    return add('config-list-'+prefix,'XCConfigurationList',
               buildConfigurations=[ref(c) for c in configs],
               defaultConfigurationIsVisible='0', defaultConfigurationName='Release')

project_config = conf_list('project', [config(project_debug,'project','Debug'),config(project_release,'project','Release')])

common = {'CLANG_ENABLE_MODULES':'YES', 'SWIFT_VERSION':'5.0',
          'CODE_SIGN_STYLE':'Automatic', 'IPHONEOS_DEPLOYMENT_TARGET':'17.0',
          'TARGETED_DEVICE_FAMILY':'1,2','GENERATE_INFOPLIST_FILE':'NO',
          'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME':'AccentColor',
          'CURRENT_PROJECT_VERSION':'1','MARKETING_VERSION':'1.0',
          'SUPPORTS_MACCATALYST':'NO','SWIFT_EMIT_LOC_STRINGS':'YES'}
app_config_base = {**common,'PRODUCT_BUNDLE_IDENTIFIER':'com.example.badminton.CourtManager',
                   'INFOPLIST_FILE':'App/Info.plist',
                   'PRODUCT_NAME':'$(TARGET_NAME)',
                   'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon'}
widget_config_base = {**common,'PRODUCT_BUNDLE_IDENTIFIER':'com.example.badminton.CourtManager.LiveActivity',
                      'INFOPLIST_FILE':'WidgetExtension/Info.plist',
                      'PRODUCT_NAME':'$(TARGET_NAME)',
                      'APPLICATION_EXTENSION_API_ONLY':'YES','SKIP_INSTALL':'YES'}
app_config = conf_list('app',[
    config(app_config_base,'app','Debug'),config(app_config_base,'app','Release')])
widget_config = conf_list('widget',[
    config(widget_config_base,'widget','Debug'),config(widget_config_base,'widget','Release')])

app_target = add('target-app','PBXNativeTarget',buildConfigurationList=ref(app_config),
                 buildPhases=[ref(app_sources),ref(app_frameworks),ref(app_resources),ref(embed_phase)],
                 buildRules=[],dependencies=[ref(dep)],name='BadmintonCourtManager',
                 productName='BadmintonCourtManager',productReference=ref(app_product),
                 productType='com.apple.product-type.application')
widget_target = add('target-widget','PBXNativeTarget',buildConfigurationList=ref(widget_config),
                    buildPhases=[ref(widget_sources),ref(widget_frameworks),ref(widget_resources)],
                    buildRules=[],dependencies=[],name='CourtLiveActivityExtension',
                    productName='CourtLiveActivityExtension',productReference=ref(widget_product),
                    productType='com.apple.product-type.app-extension')
project_id = add('project','PBXProject',attributes={
    'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'1500',
    'TargetAttributes':{app_target:{'CreatedOnToolsVersion':'15.0','ProvisioningStyle':'Automatic'},
                        widget_target:{'CreatedOnToolsVersion':'15.0','ProvisioningStyle':'Automatic'}}},
    buildConfigurationList=ref(project_config),compatibilityVersion='Xcode 14.0',
    developmentRegion='en',hasScannedForEncodings='0',knownRegions=['en','Base'],
    mainGroup=ref(main_group),productRefGroup=ref(products),projectDirPath='',projectRoot='',
    targets=[ref(app_target),ref(widget_target)])

out = '// !$*UTF8*$!\n{\n'
out += '\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n'
out += '\tobjects = {\n'
for key,obj in OBJS.items():
    out += f'\t\t{key} = '+fmt(obj,2)+';\n'
out += '\t};\n\trootObject = '+project_id+';\n}\n'
(PROJECT/'project.pbxproj').write_text(out)

workspace = PROJECT / 'project.xcworkspace'
workspace.mkdir(exist_ok=True)
(workspace / 'contents.xcworkspacedata').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<Workspace version="1.0"><FileRef location="self:"></FileRef></Workspace>
''')

schemes = PROJECT / 'xcshareddata' / 'xcschemes'
schemes.mkdir(parents=True,exist_ok=True)
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="BadmintonCourtManager.app" BlueprintName="BadmintonCourtManager" ReferencedContainer="container:BadmintonCourtManager.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
    <Testables></Testables>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="BadmintonCourtManager.app" BlueprintName="BadmintonCourtManager" ReferencedContainer="container:BadmintonCourtManager.xcodeproj"/></BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="BadmintonCourtManager.app" BlueprintName="BadmintonCourtManager" ReferencedContainer="container:BadmintonCourtManager.xcodeproj"/></BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
(schemes / 'BadmintonCourtManager.xcscheme').write_text(scheme)
print('Generated', PROJECT, 'with',len(OBJS),'objects')
