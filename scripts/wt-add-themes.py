"""Add color schemes to Windows Terminal settings.json"""
import json, os, sys, glob

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
    print("Windows Terminal settings.json not found")
    sys.exit(1)

with open(cfg, "r", encoding="utf-8") as f:
    data = json.load(f)

themes_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wt-themes")
schemes = data.setdefault("schemes", [])
existing = {s.get("name") for s in schemes}

added = 0
for fpath in sorted(glob.glob(os.path.join(themes_dir, "*.json"))):
    with open(fpath, "r", encoding="utf-8") as f:
        scheme = json.load(f)
    name = scheme.get("name")
    if not name or name in existing:
        continue
    schemes.append(scheme)
    existing.add(name)
    added += 1
    print(f"Added scheme '{name}'")

if added == 0:
    print("No new schemes to add")
    sys.exit(0)

with open(cfg, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
print(f"Added {added} scheme(s) to {cfg}")
