"""Adjust the matching Godot 4.6 template for Android 16 before Gradle export."""
from pathlib import Path
import re

config = Path("android/build/config.gradle")
source = config.read_text(encoding="utf-8")
changes = [(r"(androidGradlePlugin\s*:\s*)'8\.6\.1'", r"\g<1>'8.9.1'"),
           (r"(compileSdk\s*:\s*)35", r"\g<1>36"),
           (r"(targetSdk\s*:\s*)35", r"\g<1>36")]
for pattern, replacement in changes:
    source, count = re.subn(pattern, replacement, source)
    if count != 1:
        raise SystemExit("Unexpected Android template. Use matching Godot 4.6 templates.")
config.write_text(source, encoding="utf-8")
print("Prepared compile/target SDK 36 and AGP 8.9.1 (Gradle wrapper stays 8.11.1).")
