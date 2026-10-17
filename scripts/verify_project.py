"""Checks source syntax and Xcode project structure; does not compile Swift or run XCTest.
Install verifier-only dependencies: pip install tree-sitter tree-sitter-swift openstep-parser
Run from this project's directory: python scripts/verify_project.py
"""
import json
import plistlib
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from tree_sitter import Language, Parser
import tree_sitter_swift
from openstep_parser import OpenStepDecoder

root = Path(__file__).resolve().parents[1]
parser = Parser(Language(tree_sitter_swift.language()))
results = []
errors = []
for path in sorted(root.rglob("*.swift")):
    source = path.read_bytes()
    tree = parser.parse(source)
    issues = []
    stack = [tree.root_node]
    while stack:
        node = stack.pop()
        if node.type == "ERROR" or node.is_missing:
            issues.append({"line": node.start_point.row + 1, "type": node.type,
                           "text": source[node.start_byte:node.end_byte].decode(errors="replace")[:120]})
        stack.extend(reversed(node.children))
    results.append({"file": str(path.relative_to(root)), "syntax_errors": issues})
    errors.extend(issues)
project = OpenStepDecoder.ParseFromString((root / "RingRebuilt.xcodeproj/project.pbxproj").read_text())
objects = project["objects"]
manifest = json.loads((root / "project-manifest.json").read_text())
actual_sources = {p.relative_to(root / "RingRebuilt").as_posix()
                  for p in (root / "RingRebuilt").rglob("*.swift")}
assert set(manifest["app_sources"]) == actual_sources, "App source manifest mismatch"
referenced_sources = {o["path"] for o in objects.values()
                      if o.get("isa") == "PBXFileReference" and o.get("lastKnownFileType") == "sourcecode.swift"}
assert actual_sources.issubset(referenced_sources), "A Swift file is missing from the Xcode project"
build_refs = {o["fileRef"] for o in objects.values() if o.get("isa") == "PBXBuildFile"}
for key, obj in objects.items():
    if obj.get("isa") == "PBXFileReference" and obj.get("lastKnownFileType") == "sourcecode.swift":
        assert key in build_refs, "Swift reference has no build record"
    if obj.get("isa") == "PBXSourcesBuildPhase":
        for build in obj["files"]:
            assert build in objects and objects[build]["fileRef"] in objects
info = plistlib.loads((root / "RingRebuilt/Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "$(PRODUCT_BUNDLE_IDENTIFIER)"
assert "NSCameraUsageDescription" in info
assert "NSAllowsArbitraryLoads" not in json.dumps(info)
scheme = ET.parse(root / "RingRebuilt.xcodeproj/xcshareddata/xcschemes/RingRebuilt.xcscheme")
for build in scheme.findall(".//BuildableReference"):
    assert build.attrib["BlueprintIdentifier"] in objects
icon = json.loads((root / "RingRebuilt/Assets.xcassets/AppIcon.appiconset/Contents.json").read_text())
assert (root / "RingRebuilt/Assets.xcassets/AppIcon.appiconset" / icon["images"][0]["filename"]).exists()
report = {
    "swift_files": len(results), "syntax_errors": len(errors), "sources": results,
    "project_object_count": len(objects), "xcode_project_parse": "passed",
    "source_membership": "passed", "plist_and_scheme": "passed", "icon": "passed",
    "compiler_typecheck": "not run: requires macOS and Xcode",
    "xctest_execution": "not run: requires macOS and Xcode",
    "device_execution": "not run: requires signed Xcode build"
}
(root / "validation-report.json").write_text(json.dumps(report, indent=2))
print(json.dumps({k: v for k, v in report.items() if k != "sources"}, indent=2))
sys.exit(1 if errors else 0)

