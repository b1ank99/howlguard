"""CI editor configuration. Release passwords are read only from environment."""
import os
from pathlib import Path
import json

settings = Path.home() / ".config/godot/editor_settings-4.6.tres"
settings.parent.mkdir(parents=True, exist_ok=True)
sdk = os.environ["ANDROID_HOME"]
java = os.environ["JAVA_HOME"]
debug = str(Path.home() / ".android/debug.keystore")
settings.write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    + f'export/android/android_sdk_path = {json.dumps(sdk)}\n'
    + f'export/android/java_sdk_path = {json.dumps(java)}\n'
    + f'export/android/debug_keystore = {json.dumps(debug)}\n'
    + 'export/android/debug_keystore_user = "androiddebugkey"\n'
    + 'export/android/debug_keystore_pass = "android"\n', encoding="utf-8"
)
