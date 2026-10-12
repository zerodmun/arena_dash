#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
QA_SDK="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
QA_TOOLS="$QA_SDK/build-tools/36.0.0"
QA_JAR="$QA_SDK/platforms/android-33/android.jar"
QA_OUTPUT="qa/phone-qa/helper"
mkdir -p "$QA_OUTPUT/classes"
javac --release 8 -classpath "$QA_JAR" -d "$QA_OUTPUT/classes" tools/android_multitouch/TouchRunner.java
"$QA_TOOLS/d8" --lib "$QA_JAR" --output "$QA_OUTPUT" "$QA_OUTPUT/classes/com/arenadash/qa/TouchRunner.class"
"$QA_TOOLS/aapt" package -f -M tools/android_multitouch/AndroidManifest.xml -I "$QA_JAR" -F "$QA_OUTPUT/unsigned.apk"
(cd "$QA_OUTPUT" && zip -q unsigned.apk classes.dex)
"$QA_TOOLS/apksigner" sign --ks debug.keystore --ks-pass pass:android --out "$QA_OUTPUT/multitouch-qa.apk" "$QA_OUTPUT/unsigned.apk"
