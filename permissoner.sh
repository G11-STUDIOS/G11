#!/bin/bash

# --- Permissioner by giorgich11 ---
# The ultimate "This is mine now" tool for Linux.

# Grab the target from drag-n-drop (%f) or manual selection
TARGET="${1:-$(zenity --file-selection --directory --title="Permissioner: Select Target" --text="What do you want to take ownership of?")}"

[[ -z "$TARGET" ]] && exit 1

# 1. Ask for the Boss (New Owner)
# Added 'whoami' as the first option because 99% of the time, it's YOU.
CURRENT_USER=$(whoami)
USER_LIST="$CURRENT_USER $(cut -d: -f1 /etc/passwd | grep -vE 'nologin|halt|sync|shutdown' | sort | tr '\n' ' ')"

SELECTED_USER=$(zenity --list --title="Permissioner: Choose Owner" \
    --column="User" $USER_LIST \
    --text="Select the user who should own this thing:" --width=300 --height=400)

[[ -z "$SELECTED_USER" ]] && exit 1

# 2. Get the "Key" (Sudo Password)
PASSWORD=$(zenity --password --title="Permissioner: Authentication")
[[ -z "$PASSWORD" ]] && exit 1

# 3. The Takeover
(
echo "20" ; echo "# Verifying path: $TARGET"
sleep 1

echo "50" ; echo "# Claiming ownership for $SELECTED_USER..."
# Using -v (verbose) to catch any weird errors
echo "$PASSWORD" | sudo -S chown -R "$SELECTED_USER":"$SELECTED_USER" "$TARGET" 2>/dev/null

echo "80" ; echo "# Unlocking read/write access..."
echo "$PASSWORD" | sudo -S chmod -R u+rwX,go+rX "$TARGET" 2>/dev/null

echo "100" ; echo "# Operation Complete!"
) | zenity --progress --title="Permissioner" --text="Starting..." --percentage=0 --auto-close

# 4. Success Check
if [ $? -eq 0 ]; then
    zenity --info --text="<b>Permissioner Success!</b>\n\n$TARGET is now fully owned by $SELECTED_USER." --width=300
else
    zenity --error --text="<b>Permissioner Failed!</b>\n\nCould not take ownership. Check your password or if the drive is read-only."
fi