#!/bin/bash
# Master Factory Script V0.3 - Hardened & Fixed
# Architecture by Vladi Mushkudiani

# 1. Pre-Flight Check (Ensures you have the tools)
for cmd in zenity shc upx strip objcopy; do
    if ! command -v $cmd &> /dev/null; then
        zenity --error --title="FACTORY ERROR" --text="Missing tool: $cmd\nInstall it with: sudo pacman -S $cmd"
        exit 1
        fi
        done
        
        APP_NAME=$(zenity --entry --title="MASTER FACTORY V3" --window-icon="system-run" --text="Enter App Name:")
        [ -z "$APP_NAME" ] && exit
        
        # 2. Setup Temp File with Auto-Shebang
        TEMP_CODE_FILE=$(mktemp)
        echo "#!/bin/bash" > "$TEMP_CODE_FILE"
        
        zenity --text-info --title="PASTE YOUR BASH SCRIPT" \
        --window-icon="edit-paste" \
        --text="Paste below (don't worry about the #!/bin/bash, I'll add it):" \
        --editable >> "$TEMP_CODE_FILE"
        
        # 3. Validation: Did you actually paste code?
        # (Checks if file has more than just the 1-line shebang we added)
        if [ $(wc -l < "$TEMP_CODE_FILE") -le 1 ]; then
            zenity --error --title="FACTORY ERROR" --text="No code provided. Shutting down."
            rm "$TEMP_CODE_FILE"
            exit
            fi
            
            FINAL_SH="${APP_NAME}.sh"
            mv "$TEMP_CODE_FILE" "$FINAL_SH"
            chmod +x "$FINAL_SH"
            
            # 4. The Compilation Forge
            if zenity --question --title="COMPILE?" --text="Convert $FINAL_SH to a hardened .bin?"; then
                
                (
                    echo "10" ; echo "# Shielding script with SHC..." ; sleep 0.2
                    shc -r -f "$FINAL_SH" -o "${APP_NAME}.bin" > /dev/null 2>&1
                    
                    echo "30" ; echo "# Stripping debug symbols..." ; sleep 0.2
                    strip --strip-all "${APP_NAME}.bin"
                    
                    echo "50" ; echo "# Ultra-Packing (UPX)..." 
                    upx --ultra-brute "${APP_NAME}.bin" > /dev/null 2>&1
                    
                    echo "70" ; echo "# Injecting G11 Signature..."
                    # Using 'sed' with '-z' to safely handle the binary stream
                    sed -i -z 's/UPX!/G11!/g' "${APP_NAME}.bin"
                    
                    echo "85" ; echo "# Scrubbing GCC metadata..."
                    # This removes the "Compiled with GCC" strings that trackers look for
                    objcopy --remove-section=.comment --remove-section=.note "${APP_NAME}.bin"
                    
                    echo "95" ; echo "# Cleaning scrap metal..."
                    rm -f "${FINAL_SH}.x.c"
                    
                    echo "100"
                ) | zenity --progress --title="FACTORY WORKING" --auto-close --pulsate
                
                zenity --info --title="MISSION COMPLETE" --text="Success!\n\n📄 Script: $FINAL_SH\n🚀 Binary: ${APP_NAME}.bin\n🔑 Signature: G11!"
                else
                    zenity --info --title="DONE" --text="Success!\n\nCreated: $FINAL_SH"
                    fi
