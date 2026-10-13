"""Check the Godot 4.7.2 template and select an API-36-capable Gradle plugin."""
from pathlib import Path
import re

config = Path("android/build/config.gradle")
source = config.read_text(encoding="utf-8")
for field in ["compileSdk", "targetSdk"]:
    if not re.search(rf"{field}\s*:\s*36", source):
        raise SystemExit("Expected SDK 36 from matching Godot 4.7.2 templates.")
source, count = re.subn(r"(androidGradlePlugin\s*:\s*)'8\.6\.1'", r"\g<1>'8.9.1'", source)
if count != 1 and not re.search(r"androidGradlePlugin\s*:\s*'8\.9\.1'", source):
    raise SystemExit("Unexpected Gradle plugin version. Check the template.")
config.write_text(source, encoding="utf-8")
print("Prepared compile/target SDK 36 and AGP 8.9.1 (Gradle wrapper stays 8.11.1).")
