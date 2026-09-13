#!/bin/bash

# --- giorgich11: Wine Fortress & Sandboxer PRO 2026 ---

# 1. Main Dashboard
ACTION=$(zenity --list --title="🍷 Wine Fortress PRO" --width=400 --height=300 \
    --column="Icon" --column="Task" \
    "📦" "Install/Sandbox New App" \
    "🗑️" "Uninstall/Manage Prefix" \
    "🔄" "Restore from Snapshot")
[ -z "$ACTION" ] && exit 0

# --- MANAGER / UNINSTALLER ---
if [[ "$ACTION" == *"Uninstall"* ]]; then
    DIR=$(zenity --file-selection --directory --title="Select Fortress Folder")
    [ -d "$DIR/prefix" ] && WINEPREFIX="$DIR/prefix" wine uninstaller
    exit 0
fi

# --- INSTALLER FLOW ---
EXE_PATH=$(zenity --file-selection --title="🎯 Select Installer (.exe/.msi)")
[ -z "$EXE_PATH" ] && exit 0

BASE_DIR=$(zenity --file-selection --directory --title="📂 Where to build the Fortress?")
APP_NAME=$(zenity --entry --title="📛 App Name" --text="Enter the name for this sandbox:" --entry-text="NewApp")
SANDBOX_DIR="$BASE_DIR/${APP_NAME}_Fortress"
mkdir -p "$SANDBOX_DIR/prefix" "$SANDBOX_DIR/snapshots"

# Security Choice
zenity --question --title="🛡️ Security Level" \
    --text="Isolate this app?\n\nYES = Can't see your Linux files (Sandbox)\nNO = Normal Wine access" \
    --ok-label="Full Sandbox" --cancel-label="Access Linux"
ISOLATE=$?

# Build Process with "Animation"
(
echo "10" ; echo "# 🏗️ Prepping directory structure..." ; sleep 1
echo "30" ; echo "# 🍷 Initializing Prefix (Wine 11.0+)..." ; WINEPREFIX="$SANDBOX_DIR/prefix" winecfg /v win10 > /dev/null 2>&1
echo "50" ; echo "# 📸 Taking pre-install snapshot..." ; tar -czf "$SANDBOX_DIR/snapshots/pre_install.tar.gz" -C "$SANDBOX_DIR/prefix" .
echo "70" ; echo "# 🔐 Hardening Environment..."
if [ $ISOLATE -eq 0 ]; then
    rm "$SANDBOX_DIR/prefix/dosdevices/z:" 2>/dev/null
    for folder in Documents Desktop Pictures Videos Music; do
        rm -rf "$SANDBOX_DIR/prefix/drive_c/users/$(whoami)/$folder"
        mkdir -p "$SANDBOX_DIR/prefix/drive_c/users/$(whoami)/$folder"
    done
fi
echo "100" ; echo "# 🚀 Ready to launch!"
) | zenity --progress --title="Building Fortress" --auto-close --pulsate

# Run the Installer
WINEPREFIX="$SANDBOX_DIR/prefix" wine "$EXE_PATH"

# FINAL STEP: Create the Launcher & Desktop Entry
FINAL_EXE=$(zenity --file-selection --filename="$SANDBOX_DIR/prefix/drive_c/" --title="🎯 Find the INSTALLED .exe (not the installer)")

cat <<EOF > "$SANDBOX_DIR/launch.sh"
#!/bin/bash
export WINEPREFIX="\$(dirname "\$(readlink -f "\$0")")/prefix"
wine "$FINAL_EXE"
EOF
chmod +x "$SANDBOX_DIR/launch.sh"

# Desktop Shortcut
SHORTCUT="$HOME/.local/share/applications/${APP_NAME}.desktop"
cat <<EOF > "$SHORTCUT"
[Desktop Entry]
Name=${APP_NAME} (Fortress)
Exec=env WINEPREFIX="$SANDBOX_DIR/prefix" wine "$FINAL_EXE"
Type=Application
Categories=Wine;
Terminal=false
Icon=wine
EOF
chmod +x "$SHORTCUT"

zenity --info --title="Victory" --text="App installed!\n\n1. Launcher: $SANDBOX_DIR/launch.sh\n2. Start Menu: Added successfully!"