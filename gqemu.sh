#!/bin/bash

# --- 1. FILE SELECTION ---
ISO_PATH=$(zenity --file-selection --title="Select ISO")
[[ -z "$ISO_PATH" ]] && exit 1

# --- 2. STORAGE LOGIC ---
ACTION=$(zenity --list --title="Drive Strategy" --radiolist \
--column="Pick" --column="Mode" \
TRUE "Create New Drive" \
FALSE "Load Existing Drive" \
FALSE "Live Mode (No Disk)")

DISK_OPTS=""
if [[ "$ACTION" == "Create New Drive" ]]; then
	DISK_PATH=$(zenity --file-selection --save --title="Save Virtual Drive" --filename="vm_disk.qcow2")
	[[ -z "$DISK_PATH" ]] && exit 1
	SIZE=$(zenity --entry --title="Disk Size" --text="Size (e.g. 40G)")
	SIZE=${SIZE:-40G}
	mkdir -p "$(dirname "$DISK_PATH")"
	qemu-img create -f qcow2 "$DISK_PATH" "$SIZE"
	DISK_OPTS="-drive file=$DISK_PATH,format=qcow2"
	elif [[ "$ACTION" == "Load Existing Drive" ]]; then
	DISK_PATH=$(zenity --file-selection --title="Select Disk")
	DISK_OPTS="-drive file=$DISK_PATH,format=qcow2"
	fi
	
	# --- 3. THE HARDWARE FORM ---
	CONFIG=$(zenity --forms --title="VM Config" \
	--add-entry="RAM (Default 4G)" \
	--add-entry="CPU Cores (Default 4)" \
	--add-list="Graphics" --list-values="virtio|std|vmware|qxl" \
	--add-list="Network" --list-values="Online|Offline" \
	--add-list="Boot" --list-values="BIOS|UEFI" \
	--add-entry="Shared Folder Path" \
	--add-entry="USB ID (Vendor:Product)")
	
	[[ -z "$CONFIG" ]] && exit 1
	
	# --- 4. CLEAN PARSING (The Fix) ---
	# We use 'tr' to delete any trailing commas or whitespace Zenity might have added
	RAM=$(echo $CONFIG | cut -d'|' -f1 | tr -d ' ,'); RAM=${RAM:-4G}
	CORES=$(echo $CONFIG | cut -d'|' -f2 | tr -d ' ,'); CORES=${CORES:-4}
	VGA=$(echo $CONFIG | cut -d'|' -f3 | tr -d ' ,'); VGA=${VGA:-virtio}
	NET=$(echo $CONFIG | cut -d'|' -f4 | tr -d ' ,')
	BOOT=$(echo $CONFIG | cut -d'|' -f5 | tr -d ' ,')
	SHARE_PATH=$(echo $CONFIG | cut -d'|' -f6) # Don't strip spaces from paths!
	USB_ID=$(echo $CONFIG | cut -d'|' -f7 | tr -d ' ,')
	
	# Feature logic
	FW_OPTS=""
	[[ "$BOOT" == "UEFI" && -f "/usr/share/OVMF/OVMF_CODE.fd" ]] && \
	FW_OPTS="-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"
	
	NET_OPTS="-net none"
	[[ "$NET" == "Online" ]] && NET_OPTS="-net nic -net user"
	
	SHARE_OPTS=""
	[[ ! -z "$SHARE_PATH" ]] && \
	SHARE_OPTS="-virtfs local,path=$SHARE_PATH,mount_tag=hostshare,security_model=mapped-xattr"
	
	USB_OPTS=""
	if [[ ! -z "$USB_ID" ]]; then
		V_ID=$(echo $USB_ID | cut -d: -f1)
		P_ID=$(echo $USB_ID | cut -d: -f2)
		USB_OPTS="-device qemu-xhci -device usb-host,vendorid=0x$V_ID,productid=0x$P_ID"
		fi
		
		# --- 5. LAUNCH ---
		qemu-system-x86_64 \
		-enable-kvm \
		-m "$RAM" \
		-smp "$CORES" \
		-cpu host \
		-cdrom "$ISO_PATH" \
		$DISK_OPTS \
		$FW_OPTS \
		$NET_OPTS \
		$SHARE_OPTS \
		$USB_OPTS \
		-vga "$VGA" \
		-display gtk,zoom-to-fit=on \
		-device intel-hda -device hda-duplex \
		-usb -device usb-tablet \
		-boot d &
		
		notify-send "G-QEMU" "Blasting off without commas! 🚀"
