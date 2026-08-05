"""Add MSYS2 profile to Windows Terminal settings.json"""
import json, os, sys

MSYS_ROOT = os.environ.get("MSYS2_ROOT", "")
MSYSTEM = os.environ.get("MSYSTEM", "UCRT64")
NAME = f"{MSYSTEM} / zsh"

if not MSYS_ROOT:
    import subprocess
    r = subprocess.run(["cygpath", "-w", "/"], capture_output=True, text=True)
    MSYS_ROOT = r.stdout.strip().rstrip("\\") + "\\"

PROFILE = {
    "name": NAME,
    "commandline": f'{MSYS_ROOT}msys2_shell.cmd -defterm -here -no-start -{MSYSTEM.lower()} -shell zsh',
    "icon": f'{MSYS_ROOT}{MSYSTEM.lower()}.ico',
    "startingDirectory": "%USERPROFILE%"
}

# Find or create WT settings
paths = [
    os.path.expandvars(r"%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json"),
]
cfg = None
for p in paths:
    if os.path.exists(p):
        cfg = p
        break
if not cfg:
    cfg = paths[1]
    os.makedirs(os.path.dirname(cfg), exist_ok=True)
    with open(cfg, "w", encoding="utf-8") as f:
        json.dump({"profiles": {"defaults": {}, "list": []}}, f, indent=4)

with open(cfg, "r", encoding="utf-8") as f:
    data = json.load(f)

# Add profile if not exists
data.setdefault("profiles", {}).setdefault("list", [])
existing = [p for p in data["profiles"]["list"] if p.get("name") == NAME]
if existing:
    print(f"Profile '{NAME}' already exists in {cfg}")
    sys.exit(0)

data["profiles"]["list"].append(PROFILE)
with open(cfg, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
print(f"Added '{NAME}' to {cfg}")
