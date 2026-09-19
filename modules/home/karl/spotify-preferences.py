"""Apply managed preferences before Spotify starts, preserving other settings."""

import json
import os
from pathlib import Path
import re
import sys
import tempfile
import zipfile


def patch_startup_preferences(path):
    """Initialize the native tray preference without visiting the Settings route."""
    with zipfile.ZipFile(path) as archive:
        entries = [(info, archive.read(info)) for info in archive.infolist()]
    matches = 0
    patched = []
    for info, content in entries:
        if info.filename == "xpui-snapshot.js":
            source = content.decode()
            pattern = (
                r'(class (\w+) extends \w+\{static identifier="ui\.minimize_to_tray";'
                r'.*?constructor\((\w+)\)\{super\(\3,\2\.identifier,\2\.serialize,\2\.deserialize\))'
            )
            source, matches = re.subn(
                pattern,
                r'\1;this.getValue().then(()=>this.setValue(true)).catch(error=>console.error("Tray initialization failed",error))',
                source,
            )
            content = source.encode()
        patched.append((info, content))
    if matches != 1:
        raise RuntimeError(f"Expected one Spotify tray preference constructor, found {matches}; review upstream changes")
    with zipfile.ZipFile(path, "w") as archive:
        for info, content in patched:
            archive.writestr(info, content)


def update_preferences(path, settings):
    original = path.read_text()
    lines = [
        line for line in original.splitlines()
        if line.partition("=")[0] not in settings
    ]
    lines.extend(f"{key}={json.dumps(value)}" for key, value in settings.items())
    updated = "\n".join(lines) + "\n"
    if updated == original:
        return
    # Keep the account's preferences writable and replace them atomically.
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as temp:
        temp.write(updated)
        temporary = Path(temp.name)
    try:
        temporary.chmod(path.stat().st_mode & 0o777)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    if sys.argv[1] == "--patch-xpui":
        patch_startup_preferences(Path(sys.argv[2]))
        sys.exit(0)
    settings = json.loads(Path(sys.argv[1]).read_text())
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    # These are account preferences, not the global Spotify prefs file.
    for prefs in (config / "spotify" / "Users").glob("*-user/prefs"):
        update_preferences(prefs, settings)
