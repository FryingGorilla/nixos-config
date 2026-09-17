"""Apply managed preferences before Spotify starts, preserving other settings."""

import json
import os
from pathlib import Path
import sys
import tempfile


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
    settings = json.loads(Path(sys.argv[1]).read_text())
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    # These are account preferences, not the global Spotify prefs file.
    for prefs in (config / "spotify" / "Users").glob("*-user/prefs"):
        update_preferences(prefs, settings)
