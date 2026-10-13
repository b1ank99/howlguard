#!/usr/bin/env bash
set -euo pipefail
version=4.7.2
base="https://github.com/godotengine/godot/releases/download/${version}-stable"
curl --fail --location --retry 3 "$base/Godot_v${version}-stable_linux.x86_64.zip" -o /tmp/godot.zip
unzip -q /tmp/godot.zip -d /tmp/godot-bin
sudo install -m 755 "/tmp/godot-bin/Godot_v${version}-stable_linux.x86_64" /usr/local/bin/godot
curl --fail --location --retry 3 "$base/Godot_v${version}-stable_export_templates.tpz" -o /tmp/templates.tpz
unzip -q /tmp/templates.tpz -d /tmp/godot-templates
mkdir -p "$HOME/.local/share/godot/export_templates/${version}.stable"
cp /tmp/godot-templates/templates/* "$HOME/.local/share/godot/export_templates/${version}.stable/"
godot --version
