import json, plistlib, hashlib
from pathlib import Path
root=Path('RingRebuilt')
app=root/'RingRebuilt'
sources=sorted(p.relative_to(app).as_posix() for p in app.rglob('*.swift'))
def ident(value): return hashlib.sha256(value.encode()).hexdigest()[:24].upper()
def quote(value): return json.dumps(value)
objects={}
def obj(key,body): objects[ident(key)]=body; return ident(key)
def ref(key): return ident(key)
for s in sources:
    obj('ref:'+s,'{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = '+quote(s)+'; sourceTree = "<group>"; }')
    obj('build:'+s,'{isa = PBXBuildFile; fileRef = '+ref('ref:'+s)+'; }')
obj('testref','{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppStoreTests.swift; sourceTree = "<group>"; }')
obj('testbuild','{isa = PBXBuildFile; fileRef = '+ref('testref')+'; }')
obj('assetref','{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }')
obj('assetbuild','{isa = PBXBuildFile; fileRef = '+ref('assetref')+'; }')
obj('info','{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }')
obj('appProduct','{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = RingRebuilt.app; sourceTree = BUILT_PRODUCTS_DIR; }')
obj('testProduct','{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = RingRebuiltTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }')
obj('appGroup','{isa = PBXGroup; children = ('+','.join(ref('ref:'+s) for s in sources)+','+ref('info')+','+ref('assetref')+'); path = RingRebuilt; sourceTree = "<group>"; }')
obj('testGroup','{isa = PBXGroup; children = ('+ref('testref')+'); path = Tests; sourceTree = "<group>"; }')
obj('products','{isa = PBXGroup; children = ('+ref('appProduct')+','+ref('testProduct')+'); name = Products; sourceTree = "<group>"; }')
obj('mainGroup','{isa = PBXGroup; children = ('+ref('appGroup')+','+ref('testGroup')+','+ref('products')+'); sourceTree = "<group>"; }')
for kind in ['app','test']:
    ids=[ref('build:'+s) for s in sources] if kind=='app' else [ref('testbuild')]
    obj(kind+'Sources','{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ('+','.join(ids)+'); runOnlyForDeploymentPostprocessing = 0; }')
    obj(kind+'Frameworks','{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }')
    obj(kind+'Resources','{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ('+(ref('assetbuild') if kind=='app' else '')+'); runOnlyForDeploymentPostprocessing = 0; }')
for config in ['Debug','Release']:
    common='CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0;'
    debug='ENABLE_TESTABILITY = YES; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; GCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1","$(inherited)"); SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; DEBUG_INFORMATION_FORMAT = dwarf;' if config=='Debug' else 'SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
    obj('project'+config,'{isa = XCBuildConfiguration; buildSettings = {'+common+debug+'}; name = '+config+'; }')
    appsettings='ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; DEVELOPMENT_TEAM = ""; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = RingRebuilt/Info.plist; MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = com.local.ringrebuilt; PRODUCT_NAME = "$(TARGET_NAME)"; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; TARGETED_DEVICE_FAMILY = "1,2"; SWIFT_EMIT_LOC_STRINGS = YES; ENABLE_PREVIEWS = YES;'
    obj('app'+config,'{isa = XCBuildConfiguration; buildSettings = {'+appsettings+'}; name = '+config+'; }')
    testsettings='BUNDLE_LOADER = "$(TEST_HOST)"; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/RingRebuilt.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/RingRebuilt"; GENERATE_INFOPLIST_FILE = YES; CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = ""; PRODUCT_BUNDLE_IDENTIFIER = com.local.ringrebuilt.tests; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = "1,2"; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";'
    obj('test'+config,'{isa = XCBuildConfiguration; buildSettings = {'+testsettings+'}; name = '+config+'; }')
for kind in ['project','app','test']:
    obj(kind+'Configs','{isa = XCConfigurationList; buildConfigurations = ('+ref(kind+'Debug')+','+ref(kind+'Release')+'); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }')
obj('proxy','{isa = PBXContainerItemProxy; containerPortal = '+ref('project')+'; proxyType = 1; remoteGlobalIDString = '+ref('appTarget')+'; remoteInfo = RingRebuilt; }')
obj('dependency','{isa = PBXTargetDependency; target = '+ref('appTarget')+'; targetProxy = '+ref('proxy')+'; }')
for kind,name in [('app','RingRebuilt'),('test','RingRebuiltTests')]:
    product='com.apple.product-type.application' if kind=='app' else 'com.apple.product-type.bundle.unit-test'
    obj(kind+'Target','{isa = PBXNativeTarget; buildConfigurationList = '+ref(kind+'Configs')+'; buildPhases = ('+','.join(ref(kind+x) for x in ['Sources','Frameworks','Resources'])+'); buildRules = (); dependencies = ('+(ref('dependency') if kind=='test' else '')+'); name = '+name+'; productName = '+name+'; productReference = '+ref(kind+'Product')+'; productType = '+quote(product)+'; }')
obj('project','{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {'+ref('appTarget')+' = {CreatedOnToolsVersion = 16.0; }; '+ref('testTarget')+' = {CreatedOnToolsVersion = 16.0; TestTargetID = '+ref('appTarget')+'; }; }; }; buildConfigurationList = '+ref('projectConfigs')+'; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base); mainGroup = '+ref('mainGroup')+'; productRefGroup = '+ref('products')+'; projectDirPath = ""; projectRoot = ""; targets = ('+ref('appTarget')+','+ref('testTarget')+'); }')
pbx='// !$*UTF8*$!\n{\n archiveVersion = 1;\n classes = {};\n objectVersion = 56;\n objects = {\n'+''.join(k+' = '+v+';\n' for k,v in sorted(objects.items()))+' };\n rootObject = '+ref('project')+';\n}\n'
(root/'RingRebuilt.xcodeproj/project.pbxproj').write_text(pbx)
info={'CFBundleDevelopmentRegion':'$(DEVELOPMENT_LANGUAGE)','CFBundleDisplayName':'Ring Rebuilt','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleInfoDictionaryVersion':'6.0','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL','CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)','LSRequiresIPhoneOS':True,'NSCameraUsageDescription':'Scan a QR code for local demo setup. No Ring device is paired.','UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False},'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}
(app/'Info.plist').write_bytes(plistlib.dumps(info))
scheme=f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ref('appTarget')}" BuildableName="RingRebuilt.app" BlueprintName="RingRebuilt" ReferencedContainer="container:RingRebuilt.xcodeproj"/></BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ref('testTarget')}" BuildableName="RingRebuiltTests.xctest" BlueprintName="RingRebuiltTests" ReferencedContainer="container:RingRebuilt.xcodeproj"/></TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ref('appTarget')}" BuildableName="RingRebuilt.app" BlueprintName="RingRebuilt" ReferencedContainer="container:RingRebuilt.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ref('appTarget')}" BuildableName="RingRebuilt.app" BlueprintName="RingRebuilt" ReferencedContainer="container:RingRebuilt.xcodeproj"/></BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(root/'RingRebuilt.xcodeproj/xcshareddata/xcschemes/RingRebuilt.xcscheme').write_text(scheme)
(root/'project-manifest.json').write_text(json.dumps({'app_sources':sources,'test_sources':['Tests/AppStoreTests.swift'],'targets':['RingRebuilt','RingRebuiltTests'],'app_target_id':ref('appTarget'),'test_target_id':ref('testTarget')},indent=2))
print(f'Generated Xcode project: {len(sources)} app sources, app/test targets, shared scheme.')

