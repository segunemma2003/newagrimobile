#!/bin/sh
mkdir -p "${SRCROOT}/../build/ios/${CONFIGURATION}-iphoneos" && chmod -R u+w "${SRCROOT}/../build/ios/${CONFIGURATION}-iphoneos" 2>/dev/null || true && touch "${SRCROOT}/../build/ios/${CONFIGURATION}-iphoneos/.last_build_id" 2>/dev/null || true
/bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" build
