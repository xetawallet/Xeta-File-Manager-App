#!/usr/bin/env python3
import argparse
import shutil
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = root / "App Code"
artifacts = root / "APK's (Test,Uploaded and To be Uploaded)"

parser = argparse.ArgumentParser(description="Build Xeta File Manager APK")
parser.add_argument("mode", choices=("test", "production"))
args = parser.parse_args()

if args.mode == "production" and not (app / "android" / "key.properties").is_file():
    raise SystemExit(
        "Production signing is not configured. Add android/key.properties and the private upload key, "
        "then rerun this command."
    )

kind = "debug" if args.mode == "test" else "release"
command = ["flutter", "build", "apk", f"--{kind}", "--build-name=1.0.0", "--build-number=8"]
if args.mode == "test":
    command.append("--target-platform=android-arm64")
subprocess.run(command, cwd=app, check=True)

folder = "Test" if args.mode == "test" else "To be Uploaded"
target = artifacts / folder / f"xeta-file-manager-{args.mode}-v1.0.0.apk"
target.parent.mkdir(parents=True, exist_ok=True)
source = app / "build" / "app" / "outputs" / "flutter-apk" / f"app-{kind}.apk"
shutil.copy2(source, target)
print(target)
