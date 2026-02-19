# 
#   Muna
#   Copyright © 2026 NatML Inc. All Rights Reserved.
#

from argparse import ArgumentParser
from pathlib import Path
from requests import get
from shutil import unpack_archive

parser = ArgumentParser()
parser.add_argument("--version", type=str, required=True)

def _download_fxnc(url: str, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    response = get(url)
    response.raise_for_status()
    with open(path, "wb") as f:
        f.write(response.content)
    print(f"Wrote {url} to path: {path}")
    if path.suffix == ".zip":
        unpack_archive(path, extract_dir=path.parent)
        path.unlink()
        print(f"Extracted {path}")

def main():
    args = parser.parse_args()
    version = args.version
    LIBS = [
        # Android
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/libFunction-android-armeabi-v7a.so",
            "path": Path("android") / "src" / "main" / "jniLibs" / "armeabi-v7a" / "libFunction.so"
        },
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/libFunction-android-arm64-v8a.so",
            "path": Path("android") / "src" / "main" / "jniLibs" / "arm64-v8a" / "libFunction.so"
        },
        # iOS
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/Function.xcframework.zip",
            "path": Path("ios") / "Function.xcframework.zip"
        },
        # macOS
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/Function-macos-arm64.dylib",
            "path": Path("macos") / "Function.dylib"
        },
        # Linux
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/libFunction-linux-x86_64.so",
            "path": Path("linux") / "x86_64" / "libFunction.so"
        },
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/libFunction-linux-arm64.so",
            "path": Path("linux") / "arm64" / "libFunction.so"
        },
        # Windows
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/Function-win-x86_64.dll",
            "path": Path("windows") / "x86_64" / "Function.dll"
        },
        {
            "url": f"https://cdn.fxn.ai/fxnc/{version}/Function-win-arm64.dll",
            "path": Path("windows") / "arm64" / "Function.dll"
        },
    ]
    for lib in LIBS:
        _download_fxnc(lib["url"], lib["path"])

if __name__ == "__main__":
    main()