#!/bin/bash

################
#  iOS Triage  #
################
#
# Mattia Epifani && Giovanni Rattaro

VERSION="2.0 - 20200605"

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#####################################################################
# MANDATORY REQUIREMENTS
#####################################################################
#
# - libimobiledevice
# - sshpass
# - dialog

#####################################################################
# OPTIONAL REQUIREMENTS
#####################################################################
#
# - python3
# - sysdiagnose scripts
# - APOLLO
# - iLEAPP


#####################################################################
# VARIABLES
#####################################################################

# device var
NAME=$(ideviceinfo -s -k DeviceName)
TYPE=$(ideviceinfo -s -k DeviceClass)
UDID=$(ideviceinfo -s -k UniqueDeviceID)
HWMODEL=$(ideviceinfo -s -k HardwareModel)
PRODUCT=$(ideviceinfo -s -k ProductType)
IOS_VERSION=$(ideviceinfo -s -k ProductVersion)
WIFI=$(ideviceinfo -s -k WiFiAddress)

# generic commands var
SSH_COMMAND="sshpass -p alpine ssh root@localhost"
SCP_FILE_COMMAND="sshpass -p alpine scp -p root@localhost:"
SCP_FOLDER_COMMAND="sshpass -p alpine scp -rp root@localhost:"
PYTHON3="python3"

process=1


#####################################################################
# FUNCTIONS
#####################################################################

time_update () { NOW=$(date +"%Y%m%d_%H_%M_%S"); }

set_path () {
	clear && time_update

	# Generic path var
	SPATH="$UDID"

	# Directories for device information
	INFO_DIR="${SPATH}/${NOW}_info"
	INFO_TXT_FILE="${INFO_DIR}/${NOW}_info.txt"
	INFO_PLIST_FILE="${INFO_DIR}/${NOW}_info.plist"

	# Directories for live commands execution
	LIVE_DIR="${SPATH}"/${NOW}_live
    
	# Directories for find commands execution
	FIND_DIR="${SPATH}"/${NOW}_find
	FIND_LOG_FILE="${FIND_DIR}"/${NOW}_find.log
	FIND_PRIVATE="${FIND_DIR}"/${NOW}_find_private.txt
	FIND_EMAILS="${FIND_DIR}"/${NOW}_find_emails.txt
	FIND_TWITTER_USERNAME="${FIND_DIR}"/${NOW}_find_twitter_username.txt
	FIND_SKYPE_USERNAME="${FIND_DIR}"/${NOW}_find_skype_username.txt
	FIND_ALL_FILES="${FIND_DIR}"/${NOW}_find_all_files.log
	FIND_ALL_WHATSAPP="${FIND_DIR}"/${NOW}_find_all_whatsapp.log

	# Parsed artifacts
	FIND_WHATSAPP_USERS="${FIND_DIR}"/${NOW}_find_whatsapp_users.txt
	FIND_WHATSAPP_GROUPS="${FIND_DIR}"/${NOW}_find_whatsapp_groups.txt
        FIND_PARSED_HEIC="${FIND_DIR}"/${NOW}_find_heic.txt
        FIND_PARSED_PDF="${FIND_DIR}"/${NOW}_find_pdf.txt
        FIND_PARSED_JPG="${FIND_DIR}"/${NOW}_find_jpg.txt
        FIND_PARSED_MOV="${FIND_DIR}"/${NOW}_find_mov.txt
        FIND_PARSED_TXT="${FIND_DIR}"/${NOW}_find_txt.txt
        FIND_PARSED_DOC="${FIND_DIR}"/${NOW}_find_doc.txt
        FIND_PARSED_XLS="${FIND_DIR}"/${NOW}_find_xls.txt
        FIND_PARSED_PPT="${FIND_DIR}"/${NOW}_find_ppt.txt

	# Directories for BFU relevant image
	BFU_DIR="${SPATH}/${NOW}_bfu_acquisition"
	BFU_LOG_FILE="$BFU_DIR/${NOW}_bfu_acquisition.log"

	# Directories for 'private' image
	ACQUISITION_DIR="${SPATH}/${NOW}_private_acquisition"
	ACQUISITION_LOG_FILE="${ACQUISITION_DIR}/${NOW}_private_acquisition.log"
    
	# Directories for full file system image
	ACQUISITION_DIR_FULL="${SPATH}/${NOW}_full_acquisition"
	ACQUISITION_LOG_FILE_FULL="${ACQUISITION_DIR_FULL}/${NOW}_full_acquisition.log"

	# Directories for triage image and process
	PROCESS_DIR="${SPATH}/${NOW}_triage_acquisition"
	PROCESS_LOG_FILE="$PROCESS_DIR/${NOW}_triage_acquisition.log"

}

check_device () {
	if [ "$(echo "$UDID" | grep -c found)" == "1" ];then
	   clear && dialog --title "ios triage" --msgbox "NO DEVICE CONNECTED!" 5 24 && clear && exit
	fi
}

check_dependances () {
        TOOL="ileapp.py"
        if [ "$(command -v "$TOOL" | wc -l)" == "1" ]; then
            ILEAPP="$PYTHON3 $(command -v "$TOOL")"
          else
            if [[ -f "./ileapp/$TOOL" ]]; then
                ILEAPP="$PYTHON3 ./ileapp/$TOOL"
              else
                clear && dialog --title "iOS Triage" --msgbox "$TOOL NOT FOUND! 'APOLLO, iLEAPP, sysdiagnose' option not available" 6 45 && process=0 && menu
            fi
        fi

        TOOL="apollo.py"
        if [ "$(command -v "$TOOL" | wc -l)" == "1" ]; then
            APOLLO="$PYTHON3 $(command -v "$TOOL")"
          else
            if [[ -f "./apollo/$TOOL" ]]; then
                APOLLO="$PYTHON3 ./apollo/$TOOL"
              else
                clear && dialog --title "iOS Triage" --msgbox "$TOOL NOT FOUND! 'APOLLO, iLEAPP, sysdiagnose' option not available" 6 45 && process=0 && menu
            fi
        fi

	for TOOL in sysdiagnose-mobileactivation.py sysdiagnose-mobilebackup.py sysdiagnose-wifi-icloud.py sysdiagnose-networkprefs.py sysdiagnose-networkinterfaces.py sysdiagnose-wifi-plist.py sysdiagnose-mobilecontainermanager.py sysdiagnose-appconduit.py sysdiagnose-wifi-net.py sysdiagnose-wifi-kml.py; do
    
	   toolvar=$(echo $TOOL | tr . _ | tr - _)

	   if [ "$(command -v "$TOOL" | wc -l)" == "0" ]; then
	           declare ${toolvar}="$PYTHON3 $(command -v "$TOOL")"
	    else
	      if [[ -f "./sysdiagnose/$TOOL" ]]; then
		      declare ${toolvar}="$PYTHON3 ./sysdiagnose/$TOOL"      
	       else
		 clear && dialog --title "iOS Triage" --msgbox "$TOOL NOT FOUND! 'APOLLO, iLEAPP, sysdiagnose' option not available" 6 45 && process=0 && menu 
	      fi
	   fi
	done
    
	sysdiagnose_mobileactivation_py_exec="$sysdiagnose_mobileactivation_py"
	sysdiagnose_mobilebackup_py_exec="$sysdiagnose_mobilebackup_py"
	sysdiagnose_wifi_icloud_py_exec="$sysdiagnose_wifi_icloud_py"
	sysdiagnose_networkprefs_py_exec="$sysdiagnose_networkprefs_py"
	sysdiagnose_networkinterfaces_py_exec="$sysdiagnose_networkinterfaces_py"
	sysdiagnose_wifi_plist_py_exec="$sysdiagnose_wifi_plist_py"
	sysdiagnose_mobilecontainermanager_py_exec="$sysdiagnose_mobilecontainermanager_py" 
	sysdiagnose_appconduit_py_exec="$sysdiagnose_appconduit_py"
	sysdiagnose_wifi_net_py_exec="$sysdiagnose_wifi_net_py "
	sysdiagnose_wifi_kml_py_exec="$sysdiagnose_wifi_kml_py"
}

check_ssh () {
        $SSH_COMMAND "exit"
        if [ "$?" == "255" ];then
           clear && dialog --title "iOS Triage" --yesno  "SSH IS NOT WORKING! \nVERIFY IF THE DEVICE IS JAILBROKEN AND IF IPROXY IS RUNNING! \n\nHowever are you going to collect device basic information?" 13 30
           answer=$(echo $?)
           #if yes
           if [ "$answer" == "0" ]; then
              JAILBREAK="NOK" && info_collect
             else
              clear && exit
           fi
        fi
}

info_collect () {
        set_path
        mkdir -p "$INFO_DIR"
        ideviceinfo -s > "$INFO_TXT_FILE"
        ideviceinfo -s -x > "$INFO_PLIST_FILE"

        dialog --title "iOS Triage" --msgbox "\n
        [*] Dumping info from device: ${NAME}\n
        [*] Device UDID: ${UDID}\n
        [*] Device Type: ${TYPE}\n
        [*] Hardware Model: ${HWMODEL}\n
        [*] Product Type: ${PRODUCT}\n
        [*] iOS Version: ${IOS_VERSION}\n
        [*] Wi-Fi Mac Address: ${WIFI}\n\n" 14 70

        clear && dialog --title "iOS Triage" --msgbox "DEVICE INFO acquisition completed" 5 40
        if [ "$JAILBREAK" != "NOK" ]; then
           menu
         else
           clear &&  exit
        fi
}

live_commands () {
	set_path
	mkdir -p "$LIVE_DIR"
	echo -e "[*]\n[*]\n[*] This option executes 14 live commands on the device. The executions should take about 15 seconds\n[*]\n[*]"
	echo "[*] LIVE Acquisition started at ${NOW}" | tee -a "$LIVE_DIR"/${UDID}_live_log.txt
	echo -e "[*]\n[*]"     
	echo "[*] Executing live commands"
	echo "[*] date" && $SSH_COMMAND date > "$LIVE_DIR"/${UDID}_date.txt
	echo "[*] sysctl -a" && $SSH_COMMAND sysctl -a > "$LIVE_DIR"/${UDID}_sysctl-a.txt
	echo "[*] hostname" && $SSH_COMMAND hostname > "$LIVE_DIR"/${UDID}_hostname.txt
	echo "[*] uname -a" && $SSH_COMMAND uname -a > "$LIVE_DIR"/${UDID}_uname-a.txt
	echo "[*] id" && $SSH_COMMAND id > "$LIVE_DIR"/${UDID}_id.txt
	echo "[*] df" && $SSH_COMMAND df > "$LIVE_DIR"/${UDID}_df.txt
	echo "[*] df -ah" && $SSH_COMMAND df -ah > "$LIVE_DIR"/${UDID}_df-ah.txt
	echo "[*] ifconfig -a" && $SSH_COMMAND ifconfig -a > "$LIVE_DIR"/${UDID}_ifconfig-a.txt
	echo "[*] netstat -an" && $SSH_COMMAND netstat -an > "$LIVE_DIR"/${UDID}_netstat-an.txt
	echo "[*] ltop" && $SSH_COMMAND ltop > "$LIVE_DIR"/${UDID}_ltop.txt
	echo "[*] mount" && $SSH_COMMAND mount > "$LIVE_DIR"/${UDID}_mount.txt
	echo "[*] ps -ef" && $SSH_COMMAND ps -ef > "$LIVE_DIR"/${UDID}_ps-ef.txt
	echo "[*] ps aux" && $SSH_COMMAND ps aux > "$LIVE_DIR"/${UDID}_ps_aux.txt
	echo "[*] ioreg" && $SSH_COMMAND ioreg > "$LIVE_DIR"/${UDID}_ioreg.txt
	echo -e "[*]\n[*]"     
	time_update
	echo "[*] LIVE Acquisition completed at ${NOW}" >> "$LIVE_DIR"/${UDID}_live_log.txt
    
	clear && dialog --title "iOS Triage" --msgbox "LIVE Acquisition completed at ${NOW}" 6 34
	menu
}

find_commands () {
	set_path
	mkdir -p "$FIND_DIR"
	echo -e "[*]\n[*]\n[*] This option executes 4 times the 'find' command. The execution should take about 3 to 5 minutes, depending on the amount of files\n[*]\n[*]"

	# find files
	time_update && echo "[*] find DOC(X)/XLS(X)/PPT(X)/PDF/TXT/HEIC/JPG/MOV started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/ -type f \( -iname \*.pdf -o -iname \*.doc* -o -iname \*.xls* -o -iname \*.ppt* -o -iname \*.heic* -o -iname \*.jpg -o -iname \*.txt -o -iname \*.mov \) -ls" >> "$FIND_ALL_FILES" 2>/dev/null
	time_update && echo "[*] find DOC(X)/XLS(X)/PPT(X)/PDF/TXT/HEIC/JPG/MOV completed at ${NOW}" | tee -a "$FIND_LOG_FILE"

	# EMAIL ADDRESSES search
	time_update && echo "[*] EMAIL ADRESSES search on device started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Library/DataAccess -type d -iname \"*IMAP-*\"" >> "$FIND_EMAILS" 2>/dev/null
	time_update && echo "[*] EMAIL ADRESSES search on device completed at ${NOW}" | tee -a "$FIND_LOG_FILE"

	# WHATSAPP artifacts search
	time_update && echo "[*] WhatsApp artifacts search on device started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Containers -type d \( -iname \"*@s.whatsapp.net*\" -o -iname \"*@g.us*\" \) -ls" >> "$FIND_ALL_WHATSAPP" 2>/dev/null
	time_update && echo "[*] WhatsApp artifacts search on device completed at ${NOW}" | tee -a "$FIND_LOG_FILE"

	find_results_parser
    
	# TWITTER USERNAME search
	time_update && echo -e "[*] Twitter username search started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Containers -type f -iname modelCache.sqlite3" >> "$FIND_TWITTER_USERNAME" 2>/dev/null
	time_update && echo "[*] Twitter username search completed at ${NOW}" | tee -a "$FIND_LOG_FILE" 
    
	# SKYPE USERNAME search
	time_update && echo -e "[*] Skype username search started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Containers -type f -iname s4l-*" >> "$FIND_SKYPE_USERNAME" 2>/dev/null
	time_update && echo "[*] Skype username search completed at ${NOW}" | tee -a "$FIND_LOG_FILE" 

	# find /private/var
	time_update && echo -e "[*] find /private/var started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var -ls" >> "$FIND_PRIVATE" 2>/dev/null
	time_update && echo "[*] find /private/var completed at ${NOW}" | tee -a "$FIND_LOG_FILE"  

	find_results_parser

	clear && dialog --title "iOS Triage" --msgbox "FIND commands completed at ${NOW}" 6 40
	menu
}

find_results_parser () {
	time_update && echo -e "[*] find results parser started at ${NOW}" | tee -a "$FIND_LOG_FILE"

	# WhatsApp parser
	grep "@s\.whatsapp\.net" "$FIND_ALL_WHATSAPP" >> "$FIND_WHATSAPP_USERS"
	grep "@g\.us" "$FIND_ALL_WHATSAPP" >> "$FIND_WHATSAPP_GROUPS"

	# File parser
	grep -ie "\.PDF$" "$FIND_ALL_FILES" >> "$FIND_PARSED_PDF"
	grep -ie "\.JPG$" "$FIND_ALL_FILES" >> "$FIND_PARSED_JPG"
	grep -ie "\.MOV$" "$FIND_ALL_FILES" >> "$FIND_PARSED_MOV"
	grep -ie "\.TXT$" "$FIND_ALL_FILES" >> "$FIND_PARSED_TXT"
	grep -ie "\.HEIC$" "$FIND_ALL_FILES" >> "$FIND_PARSED_HEIC"
	grep -iE "(.DOCX|.DOC)$" "$FIND_ALL_FILES" >> "$FIND_PARSED_DOC"
	grep -iE "(.XLSX|.XLS)$" "$FIND_ALL_FILES" >> "$FIND_PARSED_XLS"
	grep -iE "(.PPTX|.PPT)$" "$FIND_ALL_FILES" >> "$FIND_PARSED_PPT"

	time_update && echo -e "[*] find results parser completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
}

bfu_relevant_image () {
	set_path
	mkdir -p "$BFU_DIR"
	echo -e "[*]\n[*]\n[*] This option extracts relevant files available BFU and creates a TAR file.\n[*] The execution should take about 5 minutes.\n[*]\n[*]"
	echo "[*] BFU RELEVANT image started at ${NOW}" | tee "$BFU_LOG_FILE"
	echo -e "[*]\n[*]"

	# Default directories creation
	mkdir -p "$BFU_DIR"/extracted_files
	mkdir -p "$BFU_DIR"/extracted_files/private/var/containers
	mkdir -p "$BFU_DIR"/extracted_files/private/var/db
	mkdir -p "$BFU_DIR"/extracted_files/private/var/db/spindump
	mkdir -p "$BFU_DIR"/extracted_files/private/var/installd/Library/Logs
	mkdir -p "$BFU_DIR"/extracted_files/private/var/logs 
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/AggregateDictionary
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/AppConduit
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/ApplicationSync
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/Caches
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/Calendar
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/CallHistoryDB
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/Containers
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs/mobileactivationd
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/Preferences
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/SpringBoard
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/SMS    
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/SyncedPreferences
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/UserNotifications 
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Library/Voicemail
	mkdir -p "$BFU_DIR"/extracted_files/private/var/mobile/Media/iTunes_Control/iTunes
	mkdir -p "$BFU_DIR"/extracted_files/private/var/preferences/SystemConfiguration
	mkdir -p "$BFU_DIR"/extracted_files/private/var/wireless/Library/Databases
	mkdir -p "$BFU_DIR"/extracted_files/private/var/wireless/Library/Preferences
	mkdir -p "$BFU_DIR"/extracted_files/private/var/root/Library/Caches/locationd
	mkdir -p "$BFU_DIR"/extracted_files/private/var/root/Library/Lockdown
	mkdir -p "$BFU_DIR"/extracted_files/private/var/root/Library/Logs/MobileContainerManager
	mkdir -p "$BFU_DIR"/extracted_files/private/var/root/Library/MobileContainerManager
	mkdir -p "$BFU_DIR"/extracted_files/private/var/root/Library/Preferences

	# Data extraction
	echo "[*] Extracting /private/var/containers/Data" 
	$SCP_FOLDER_COMMAND/private/var/containers/Data "$BFU_DIR"/extracted_files/private/var/containers >> "$BFU_LOG_FILE" 2>&1	

	echo "[*] Extracting /private/var/containers/Shared" 
	$SCP_FOLDER_COMMAND/private/var/containers/Shared "$BFU_DIR"/extracted_files/private/var/containers >> "$BFU_LOG_FILE" 2>&1	

	echo "[*] Extracting /private/var/db/analyticsd" 
	$SCP_FOLDER_COMMAND/private/var/db/analyticsd "$BFU_DIR"/extracted_files/private/var/db/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/db/dhcpd_leases" 
	$SCP_FILE_COMMAND/private/var/db/dhcpd_leases "$BFU_DIR"/extracted_files/private/var/db/ >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/db/dhcpclient/leases/" 
	$SCP_FOLDER_COMMAND/private/var/db/dhcpclient/leases/ "$BFU_DIR"/extracted_files/private/var/db/dhcpclient/ >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/db/spindump/UUIDToBinaryLocations" 
	$SCP_FILE_COMMAND/private/var/db/spindump/UUIDToBinaryLocations "$BFU_DIR"/extracted_files/private/var/db/spindump/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/db/systemstats" 
	$SCP_FOLDER_COMMAND/private/var/db/systemstats "$BFU_DIR"/extracted_files/private/var/db/ >> "$BFU_LOG_FILE" 2>&1
	
	echo "[*] Extracting /private/var/installd/Library/Logs/MobileInstallation/" 
	$SCP_FOLDER_COMMAND/private/var/installd/Library/Logs/MobileInstallation/ "$BFU_DIR"/extracted_files/private/var/installd/Library/Logs/ >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/installd/Library/MobileInstallation/" 
	$SCP_FOLDER_COMMAND/private/var/installd/Library/MobileInstallation/ "$BFU_DIR"/extracted_files/private/var/installd/Library/ >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/log/" 
	$SCP_FOLDER_COMMAND/private/var/log/ "$BFU_DIR"/extracted_files/private/var/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/logs/" 
	$SCP_FOLDER_COMMAND/private/var/logs/ "$BFU_DIR"/extracted_files/private/var/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Accounts/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Accounts "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1 
    
	echo "[*] Extracting /private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb* "$BFU_DIR"/extracted_files/private/var/mobile/Library/AggregateDictionary/ >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/AppConduit/AvailableApps.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AppConduit/AvailableApps.plist "$BFU_DIR"/extracted_files/private/var/mobile/Library/AppConduit/AvailableApps.plist >> "$BFU_LOG_FILE" 2>&1
   
	echo "[*] Extracting /private/var/mobile/Library/AppConduit/AvailableCompanionApps.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AppConduit/AvailableCompanionApps.plist "$BFU_DIR"/extracted_files/private/var/mobile/Library/AppConduit/AvailableCompanionApps.plist >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/ApplicationSync/AssetSortOrder.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/ApplicationSync/AssetSortOrder.plist "$BFU_DIR"/extracted_files/private/var/mobile/Library/ApplicationSync/AssetSortOrder.plist >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.mobilesms.compose/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Caches/com.apple.mobilesms.compose "$BFU_DIR"/extracted_files/private/var/mobile/Library/Caches >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.MobileSMS/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Caches/com.apple.MobileSMS "$BFU_DIR"/extracted_files/private/var/mobile/Library/Caches >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.NanoTimeKit/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Caches/com.apple.NanoTimeKit "$BFU_DIR"/extracted_files/private/var/mobile/Library/Caches >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Calendar/Notifications.Calendar.Protected"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Calendar/Notifications.Calendar.Protected "$BFU_DIR"/extracted_files/private/var/mobile/Library/Calendar/Notifications.Calendar.Protected >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/CallHistoryDB/CallHistoryTemp.storedata"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CallHistoryDB/CallHistoryTemp.storedata* "$BFU_DIR"/extracted_files/private/var/mobile/Library/CallHistoryDB/ >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/com.apple.itunesstored/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/com.apple.itunesstored/ "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/DataAccess/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/DataAccess/ "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/DeviceRegistry/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/DeviceRegistry/ "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/DeviceRegistry.state/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/DeviceRegistry.state/ "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/FrontBoard/"    
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/FrontBoard/ "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/AppConduit/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/AppConduit "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/AppleSupport/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/AppleSupport "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Logs/com.apple.itunesstored/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/com.apple.itunesstored "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/CrashReporter/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/CrashReporter "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.log.0" 
	$SCP_FILE_COMMAND/private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.log.0 "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.log.0 >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Logs/NotificationProxy/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/NotificationProxy "$BFU_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/library/Preferences/"    
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Preferences/ "$BFU_DIR"/extracted_files/private/var/mobile/Library/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/SMS/sms-temp.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SMS/sms-temp.db* "$BFU_DIR"/extracted_files/private/var/mobile/Library/SMS/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/IconState.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/IconState.plist "$BFU_DIR"/extracted_files/private/var/mobile/Library/SpringBoard >> "$BFU_LOG_FILE" 2>&1
	
	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/DesiredIconState.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/DesiredIconState.plist "$BFU_DIR"/extracted_files/private/var/mobile/Library/SpringBoard >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/TodayViewArchive.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/TodayViewArchive.plist "$BFU_DIR"/extracted_files/private/var/mobile/Library/SpringBoard >> "$BFU_LOG_FILE" 2>&1
	
	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/LockBackgroundThumbnail.jpg"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/LockBackgroundThumbnail.jpg "$BFU_DIR"/extracted_files/private/var/mobile/Library/SpringBoard >> "$BFU_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/Synced Preferences/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/SyncedPreferences/ "$BFU_DIR"/extracted_files/private/var/mobile/Library/ >> "$BFU_LOG_FILE" 2>&1 
    
	echo "[*] Extracting /private/var/mobile/Library/TCC/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/TCC "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/UserNotifications/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/UserNotifications "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1 
    
	echo "[*] Extracting /private/var/mobile/Library/UserConfigurationProfiles/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/UserConfigurationProfiles "$BFU_DIR"/extracted_files/private/var/mobile/Library >> "$BFU_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/Voicemail/voicemail.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Voicemail/voicemail.db "$BFU_DIR"/extracted_files/private/var/mobile/Library/Voicemail >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Media/iTunes_Control/iTunes/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Media/iTunes_Control/iTunes "$BFU_DIR"/extracted_files/private/var/mobile/Media/iTunes_Control >> "$BFU_LOG_FILE" 2>&1   

	echo "[*] Extracting /private/var/preferences/"
	$SCP_FOLDER_COMMAND/private/var/preferences/ "$BFU_DIR"/extracted_files/private/var/ >> "$BFU_LOG_FILE" 2>&1   

	echo "[*] Extracting /private/var/root/Library/Caches/locationd/cache.plist"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache.plist "$BFU_DIR"/extracted_files/private/var/root/Library/Caches/locationd >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/root/Library/Caches/locationd/clients.plist"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/clients.plist "$BFU_DIR"/extracted_files/private/var/root/Library/Caches/locationd >> "$BFU_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/root/Library/Preferences/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Preferences "$BFU_DIR"/extracted_files/private/var/root/Library/ >> "$BFU_LOG_FILE" 2>&1  
    
	echo "[*] Extracting /private/var/root/Library/Lockdown/"    
	$SCP_FOLDER_COMMAND/private/var/root/Library/Lockdown/ "$BFU_DIR"/extracted_files/private/var/root/Library/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/root/Library/Logs/MobileContainerManager/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Logs/MobileContainerManager/ "$BFU_DIR"/extracted_files/private/var/root/Library/Logs/ >> "$BFU_LOG_FILE" 2>&1   

	echo "[*] Extracting /private/var/root/Library/MobileContainerManager/containers.sqlite3"
	$SCP_FILE_COMMAND/private/var/root/Library/MobileContainerManager/containers.sqlite3* "$BFU_DIR"/extracted_files/private/var/root/Library/MobileContainerManager/ >> "$BFU_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/wireless/Library/Databases/CellularUsage.db"
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/CellularUsage.db* "$BFU_DIR"/extracted_files/private/var/wireless/Library/Databases >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/wireless/Library/Databases/DataUsage.sqlite"
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/DataUsage.sqlite* "$BFU_DIR"/extracted_files/private/var/wireless/Library/Databases >> "$BFU_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/wireless/Library/Preferences/"  
	$SCP_FOLDER_COMMAND/private/var/wireless/Library/Preferences/ "$BFU_DIR"/extracted_files/private/var/wireless/Library >> "$BFU_LOG_FILE" 2>&1

	echo -e "[*]\n[*]\n[*] Creating TAR file"
	tar -cvf "$BFU_DIR"/${UDID}_bfu_acquisition.tar -C "$BFU_DIR"/extracted_files private >> "$BFU_LOG_FILE" 2>/dev/null
	time_update

	echo -e "[*]\n[*]"
	echo "[*] BFU RELEVANT  image completed at ${NOW}" | tee -a "$BFU_LOG_FILE"
	echo -e "[*]\n[*]\n[*] Calculating SHA hash"
	shasum ${BFU_DIR}/${UDID}_bfu_acquisition.tar >> "$BFU_LOG_FILE" 2>&1

	clear && dialog --title "iOS Triage" --msgbox "BFU image completed at ${NOW}" 6 40
	menu
}

private_image () {
	set_path
	mkdir -p "$ACQUISITION_DIR"
	echo -e "[*]\n[*]\n[*] This option creates a TAR file of '/private', excluding application Bundles and MobileAsset."
	echo -e "[*] When in BFU state, the execution should take about 10 to 15 minutes."
	echo -e "[*] When in AFU state, the amount of time depends on the total file size and can reach several hours."
	echo -e "[*] In our tests the average speed is about 25 GB per hour\n[*]\n[*]"
	echo -e "[*] Image of /private/ started at  ${NOW}" | tee "$ACQUISITION_LOG_FILE"
	echo -e "[*]\n[*]\n[*] Executing 'tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset'"
	$SSH_COMMAND "tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset" > "${ACQUISITION_DIR}"/${UDID}_private_acquisition.tar 2>>"$ACQUISITION_LOG_FILE"
	echo -e "[*]\n[*]"
	time_update

	echo "[*] Image of /private/ completed at ${NOW}" | tee -a "$ACQUISITION_LOG_FILE"
	echo -e "[*]\n[*]\n"
	echo "[*] sha1sum of ${SPATH}/${UDID}_private_acquisition.tar in progress" | tee -a "$ACQUISITION_LOG_FILE"
	shasum "${ACQUISITION_DIR}"/${UDID}_private_acquisition.tar | tee -a "$ACQUISITION_LOG_FILE"    
    
	clear && dialog --title "iOS Triage" --msgbox "TRIAGE image of /private/ completed at ${NOW}" 6 40
	menu
}

full_image () {
 	set_path
	mkdir -p "$ACQUISITION_DIR_FULL"
	echo -e "[*]\n[*]\n[*] This option creates a TAR file of the full file system."
	echo -e "[*] When in BFU state, the execution should take about 30 minutes."
	echo -e "[*] When in AFU state, the amount of time depends on the total file size and can reach several hours."
	echo -e "[*] In our tests the average speed is about 25 GB per hour\n[*]\n[*]"
	echo "[*] FULL image started at ${NOW}" | tee "$ACQUISITION_LOG_FILE_FULL"
	echo -e "[*]\n[*]\n[*] Executing 'tar -cf - /'"
	$SSH_COMMAND "tar -cf - /" > "${ACQUISITION_DIR_FULL}"/${UDID}_full_acquisition.tar 2>>"$ACQUISITION_LOG_FILE_FULL"
	echo -e "[*]\n[*]"
	time_update
	echo "[*] FULL image completed  ${NOW}" | tee -a "$ACQUISITION_LOG_FILE_FULL"
	echo -e "[*]\n[*]"
	echo "[*] sha1sum of ${SPATH}/${UDID}_full_acquisition.tar in progress" | tee -a "$ACQUISITION_LOG_FILE_FULL"
	shasum "${ACQUISITION_DIR_FULL}"/${UDID}_full_acquisition.tar | tee -a "$ACQUISITION_LOG_FILE_FULL"

	clear && dialog --title "iOS Triage" --msgbox "FULL image completed at ${NOW}" 6 40
	menu
}

process_relevant_files () {
	set_path
	mkdir -p "$PROCESS_DIR"
	echo -e "[*]\n[*]\n[*] This option extracts relevant files and parse them with APOLLO, iLEAPP and Sysdiagnose scripts"
	echo -e "[*] The execution should take about 5 to 10 minutes.\n[*]\n[*]"
	echo "[*] Extraction and processing started at ${NOW}" | tee "$PROCESS_LOG_FILE"
	echo -e "[*]\n[*]" | tee "$PROCESS_LOG_FILE"
	echo "[*] Extracting data for scripts"
	echo -e "[*]\n[*]" | tee "$PROCESS_LOG_FILE"
 

	# EXTRACTION RELEVANT FILES

	#/private/var/containers/
	BT_PAIRED=$(sshpass -p alpine ssh root@localhost find /private/var/containers/Shared/SystemGroup -type f -name com.apple.MobileBluetooth.ledevices.paired.db)
	BT_OTHER=$(sshpass -p alpine ssh root@localhost find /private/var/containers/Shared/SystemGroup -type f -name com.apple.MobileBluetooth.ledevices.other.db)
	POWERLOG=$(sshpass -p alpine ssh root@localhost find /private/var/containers/Shared/SystemGroup -type f -name CurrentPowerlog.PLSQL)
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/Library/Database
    
	echo "[*] Extracting /private/var/containers/Shared/SystemGroup/<GUID>/Library/Database/com.apple.MobileBluetooth.ledevices.paired.db"
	$SCP_FILE_COMMAND$BT_PAIRED "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/Library/Database
	chmod 755 "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/Library/Database/com.apple.MobileBluetooth.ledevices.paired.db
	
	echo "[*] Extracting /private/var/containers/Shared/SystemGroup/<GUID>/Library/Database/com.apple.MobileBluetooth.ledevices.other.db"    
	$SCP_FILE_COMMAND$BT_OTHER "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/Library/Database
	chmod 755 "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/Library/Database/com.apple.MobileBluetooth.ledevices.other.db
    
	echo "[*] Extracting /private/var/containers/Shared/SystemGroup/<GUID>/Library/BatteryLife/CurrentPowerlog.PLSQL"
	$SCP_FILE_COMMAND$POWERLOG "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/
	chmod 755 "$PROCESS_DIR"/extracted_files/private/var/containers/Shared/SystemGroup/CurrentPowerlog.PLSQL


	#/private/var/db/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/db/dhcpclient/leases/
    
	echo "[*] Extracting /private/var/db/dhcpclient/leases/en*"
	$SCP_FILE_COMMAND/private/var/db/dhcpclient/leases/en* "$PROCESS_DIR"/extracted_files/private/var/db/dhcpclient/leases/

	echo "[*] Extracting /private/var/db/dhcpd_leases"
	$SCP_FILE_COMMAND/private/var/db/dhcpd_leases "$PROCESS_DIR"/extracted_files/private/var/db/    

	#/private/var/installd
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/installd/Library/Logs

 	echo "[*] Extracting /private/var/installd/Library/Logs/MobileInstallation/"   
	$SCP_FOLDER_COMMAND/private/var/installd/Library/Logs/MobileInstallation/ "$PROCESS_DIR"/extracted_files/private/var/installd/Library/Logs
    
	echo "[*] Extracting /private/var/installd/Library/MobileInstallation/"
	$SCP_FOLDER_COMMAND/private/var/installd/Library/MobileInstallation/ "$PROCESS_DIR"/extracted_files/private/var/installd/Library/

    
	#/private/var/mobile/Library  
	APPLICATION_SUPPORT="Application Support/com.apple.remotemanagmentd/"
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Accounts
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/AddressBook
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/AggregateDictionary
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/"$APPLICATION_SUPPORT"    
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Caches/com.apple.routined/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Calendar    
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CallHistoryDB
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CoreDuet/Knowledge/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CoreDuet/People/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/FrontBoard
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Health/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/CrashReporter/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Mail/    
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/SMS 
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/TCC/
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/homed/  

	echo "[*] Extracting /private/var/mobile/Library/Accounts/Accounts3.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Accounts/Accounts3.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Accounts/   

	echo "[*] Extracting /private/var/mobile/Library/AddressBook/AddressBook.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AddressBook/AddressBook.sqlitedb* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/AddressBook/  

	echo "[*] Extracting /private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AddressBook/AddressBookImages.sqlitedb* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/AddressBook/ 

	echo "[*] Extracting /private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/AggregateDictionary/    

	echo "[*] Extracting /private/var/mobile/Library/AppConduit/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/AppConduit/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/Application Support/com.apple.remotemanagementd/RMAdminStore-Local.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Application\\\ Support/com.apple.remotemanagementd/RMAdminStore-Local.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/"$APPLICATION_SUPPORT"

	echo "[*] Extracting /private/var/mobile/Library/Application Support/com.apple.remotemanagementd/RMAdminStore-Cloud.sqlite"    
	$SCP_FILE_COMMAND/private/var/mobile/Library/Application\\\ Support/com.apple.remotemanagementd/RMAdminStore-Cloud.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/"$APPLICATION_SUPPORT" 
	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.routined/Local.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Caches/com.apple.routined/Local.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Caches/com.apple.routined/
	chmod 755 "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Caches/com.apple.routined/Local.sqlite

	echo "[*] Extracting /private/var/mobile/Library/Calendar/Calendar.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Calendar/Calendar.sqlitedb* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Calendar/    

  	echo "[*] Extracting /private/var/mobile/Library/CallHistoryDB/CallHistory.storedata"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CallHistoryDB/CallHistory.storedata* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CallHistoryDB/

	echo "[*] Extracting /private/var/mobile/Library/CoreDuet/coreduetd.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CoreDuet/coreduetd.db* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CoreDuet/    

	echo "[*] Extracting /private/var/mobile/Library/CoreDuet/Knowledge/knowledgeC.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CoreDuet/Knowledge/knowledgeC.db* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CoreDuet/Knowledge/

	echo "[*] Extracting /private/var/mobile/Library/CoreDuet/People/interactionC.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CoreDuet/People/interactionC.db* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/CoreDuet/People/

	echo "[*] Extracting /private/var/mobile/Library/FrontBoard/applicationState.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/FrontBoard/applicationState.db* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/FrontBoard/

	echo "[*] Extracting /private/var/mobile/Library/Health/healthdb.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Health/healthdb.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Health/

	echo "[*] Extracting /private/var/mobile/Library/Health/healthdb_secure.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Health/healthdb_secure.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Health/

	echo "[*] Extracting /private/var/mobile/Library/Logs/AppConduit/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/AppConduit/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/

	echo "[*] Extracting /private/var/mobile/Library/Logs/CrashReporter/WiFi"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/CrashReporter/WiFi/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/CrashReporter/

	echo "[*] Extracting /private/var/mobile/Library/Logs/mobileactivationd/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/mobileactivationd/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/

	echo "[*] Extracting /private/var/mobile/Library/Mail/Envelope*"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Mail/Envelope* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Mail/

	echo "[*] Extracting /private/var/mobile/Library/Mail/Protected*"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Mail/Protected* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Mail/

	echo "[*] Extracting /private/var/mobile/Library/Notes/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Notes/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/Passes/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Passes/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/PersonalizationPortrait/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/PersonalizationPortrait/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/
    
	echo "[*] Extracting /private/var/mobile/Library/Preferences/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Preferences/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/Recents/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Recents/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/Reminders/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Recents/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/Safari/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Safari/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/SMS/sms.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SMS/sms.db* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/SMS/

	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/SpringBoard/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/Suggestions/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Suggestions/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/
    
	echo "[*] Extracting /private/var/mobile/Library/SyncedPreferences/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/SyncedPreferences/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/TCC/TCC.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/TCC/TCC.db* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/TCC/
    
	echo "[*] Extracting /private/var/mobile/Library/UserNotifications/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/UserNotifications/ "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/

	echo "[*] Extracting /private/var/mobile/Library/homed/datastore.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/homed/datastore.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/homed/

    
	#/private/var/mobile/Media
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Media/iTunes_Control/iTunes
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/mobile/Media/PhotoData
    
	echo "[*] Extracting /private/var/mobile/Media/iTunes_Control/iTunes/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Media/iTunes_Control/iTunes "$PROCESS_DIR"/extracted_files/private/var/mobile/Media/iTunes_Control/ 

	echo "[*] Extracting /private/var/mobile/Media/PhotoData/Photos.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Media/PhotoData/Photos.sqlite* "$PROCESS_DIR"/extracted_files/private/var/mobile/Media/PhotoData/


	#/private/var/networkd
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/networkd/
    
	echo "[*] Extracting /private/var/networkd/netusage.sqlite"
	$SCP_FILE_COMMAND/private/var/networkd/netusage* "$PROCESS_DIR"/extracted_files/private/var/networkd/    


	#/private/var/preferences
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/preferences/SystemConfiguration
    
	echo "[*] Extracting /private/var/preferences/"
	$SCP_FOLDER_COMMAND/private/var/preferences/ "$PROCESS_DIR"/extracted_files/private/var/
    

	#/private/var/root
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/root/Library/Caches/locationd
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/root/Library/Lockdown
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/root/Library/Logs

	echo "[*] Extracting /private/var/root/Library/Caches/locationd/cache_encryptedB.db"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache_encryptedB.db* "$PROCESS_DIR"/extracted_files/private/var/root/Library/Caches/locationd/

	echo "[*] Extracting /private/var/root/Library/Caches/locationd/cache_encryptedC.db"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache_encryptedC.db* "$PROCESS_DIR"/extracted_files/private/var/root/Library/Caches/locationd/

	echo "[*] Extracting private/var/root/Library/Lockdown/data_ark.plist"
	$SCP_FILE_COMMAND/private/var/root/Library/Lockdown/data_ark.plist "$PROCESS_DIR"/extracted_files/private/var/root/Library/Lockdown/

	echo "[*] Extracting /private/var/root/Library/Logs/MobileContainerManager/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Logs/MobileContainerManager/ "$PROCESS_DIR"/extracted_files/private/var/root/Library/Logs/

	echo "[*] Extracting /private/var/root/Library/Preferences/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Preferences "$PROCESS_DIR"/extracted_files/private/var/root/Library/    


	#/private/var/wireless   
	mkdir -p "$PROCESS_DIR"/extracted_files/private/var/wireless/Library/Databases    

	echo "[*] Extracting /private/var/wireless/Library/Databases/DataUsage.sqlite"
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/DataUsage.sqlite* "$PROCESS_DIR"/extracted_files/private/var/wireless/Library/Databases/

	echo "[*] Extracting /private/var/wireless/Library/Databases/CellularUsage.db"
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/CellularUsage.db* "$PROCESS_DIR"/extracted_files/private/var/wireless/Library/Databases/

	echo "[*] Extracting /private/var/wireless/Library/Preferences/"  
	$SCP_FOLDER_COMMAND/private/var/wireless/Library/Preferences/ "$PROCESS_DIR"/extracted_files/private/var/wireless/Library

    
	### TAR CREATION ###
	echo -e "[*]\n[*]\n[*] Creating TAR file" 
	tar -cvf "$PROCESS_DIR"/${UDID}_triage_acquisition.tar -C "$PROCESS_DIR"/extracted_files private >> "$PROCESS_LOG_FILE" 2>/dev/null
	time_update

	echo -e "[*]\n[*]"    
	echo "[*] TAR triage image completed at ${NOW}" | tee -a "$PROCESS_LOG_FILE"
	echo -e "[*]\n[*]\n[*] Calculating SHA hash" 
	shasum ${PROCESS_DIR}/${UDID}_triage_acquisition.tar >> "$PROCESS_LOG_FILE" 2>&1

    
	### SYSDIAGNOSE SCRIPTS ###
	mkdir -p "$PROCESS_DIR"/sysdiagnose
	echo -e "[*]\n[*]\n[*] Executing sysdiagnose scripts\n[*]\n[*]" 

	echo "[*] Processing com.apple.wifi.plist" 
	$sysdiagnose_wifi_plist_py_exec -i "$PROCESS_DIR"/extracted_files/private/var/preferences/SystemConfiguration/com.apple.wifi.plist -t > "$PROCESS_DIR"/sysdiagnose/com.apple.wifi.plist.txt
	mv sysdiagnose-wifi-plist-output.TSV "$PROCESS_DIR"/sysdiagnose/com.apple.wifi.plist.tsv
	
	echo "[*] Processing NetworkInterfaces.plist" 
	$sysdiagnose_networkinterfaces_py_exec -i "$PROCESS_DIR"/extracted_files/private/var/preferences/SystemConfiguration/NetworkInterfaces.plist > "$PROCESS_DIR"/sysdiagnose/NetworkInterfaces.txt
	
	echo "[*] Processing Network preferences.plist" 
	$sysdiagnose_networkprefs_py_exec -i "$PROCESS_DIR"/extracted_files/private/var/preferences/SystemConfiguration/preferences.plist > "$PROCESS_DIR"/sysdiagnose/NetworkPreferences.txt
	
	echo "[*] Processing com.apple.wifid.plist" 
	$sysdiagnose_wifi_icloud_py_exec -i "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/SyncedPreferences/com.apple.wifid.plist -t > "$PROCESS_DIR"/sysdiagnose/com.apple.wifid.plist.txt
	mv sysdiagnose-wifi-icloud-output.TSV "$PROCESS_DIR"/sysdiagnose/com.apple.wifid.plist.tsv
	
	echo "[*] Processing com.apple.MobileBackup.plist" 
	$sysdiagnose_mobilebackup_py_exec -i "$PROCESS_DIR"/extracted_files/private/var/root/Library/Preferences/com.apple.MobileBackup.plist > "$PROCESS_DIR"/sysdiagnose/com.apple.MobileBackup.plist.txt
    
	echo "[*] Processing Mobile Activation logs" 
	cat "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.* > "$PROCESS_DIR"/mobileactivationd.log
	$sysdiagnose_mobileactivation_py_exec -i "$PROCESS_DIR"/mobileactivationd.log > "$PROCESS_DIR"/sysdiagnose/mobileactivationd.txt
	rm -f "$PROCESS_DIR"/mobileactivationd.log
	
	echo "[*] Processing Mobile Container Manager logs"
	cat "$PROCESS_DIR"/extracted_files/private/var/root/Library/Logs/MobileContainerManager/containermanagerd.log.* > "$PROCESS_DIR"/containermanagerd.log
	$sysdiagnose_mobilecontainermanager_py_exec -i "$PROCESS_DIR"/containermanagerd.log > "$PROCESS_DIR"/sysdiagnose/containermanagerd.txt
	rm -f "$PROCESS_DIR"/containermanagerd.log
	
	echo "[*] Processing AppConduit logs"
	cat "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/AppConduit/AppConduit.log.* > "$PROCESS_DIR"/AppConduit.log
	$sysdiagnose_appconduit_py_exec -i "$PROCESS_DIR"/AppConduit.log > "$PROCESS_DIR"/sysdiagnose/AppConduit.log.txt
	rm -f "$PROCESS_DIR"/AppConduit.log
    
	echo "[*] Processing WiFiManager logs"
	cat "$PROCESS_DIR"/extracted_files/private/var/mobile/Library/Logs/CrashReporter/WiFi/WiFiManager/* > "$PROCESS_DIR"/wifi.log
	$sysdiagnose_wifi_net_py_exec -i "$PROCESS_DIR"/wifi.log >> "$PROCESS_LOG_FILE"
	$sysdiagnose_wifi_kml_py_exec -i "$PROCESS_DIR"/wifi.log >> "$PROCESS_LOG_FILE"   
	rm -f "$PROCESS_DIR"/wifi.log

	mv wifi-buf-net_alreadyattached.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_alreadyattached.tsv
	mv wifi-buf-net_bgscan.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_bgscan.tsv
	mv wifi-buf-net_channels.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_channels.tsv
	mv wifi-buf-net_filtered.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_filtered.tsv
	mv wifi-buf-net_mru.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_mru.tsv
	mv wifi-buf-net_ppmattached.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_ppmattached.tsv
	mv wifi-buf-locations.kml "$PROCESS_DIR"/sysdiagnose/wifi_buf_locations.kml
    
	time_update
	echo -e "[*]\n[*]"    
	echo "[*] Sysdiagnose scripts completed at ${NOW}" | tee -a "$PROCESS_LOG_FILE"
	echo -e "[*]\n[*]"

 
	### ILEAPP SCRIPT ###
	mkdir -p "$PROCESS_DIR"/ileapp 
	echo -e "[*]\n[*]\n[*] Executing iLEAPP\n[*]\n[*]"

	$ILEAPP -t tar -o "$PROCESS_DIR"/ileapp -i "$PROCESS_DIR"/${UDID}_triage_acquisition.tar >> "$PROCESS_LOG_FILE"
	time_update
	echo -e "[*]\n[*]"    
	echo "[*] iLEAPP completed at ${NOW}" | tee -a "$PROCESS_LOG_FILE"
	echo -e "[*]\n[*]"


	### APOLLO SCRIPT ###
	mkdir -p "$PROCESS_DIR"/apollo
	echo -e "[*]\n[*]\n[*] Executing APOLLO\n[*]\n[*]" 

	$APOLLO -o csv -p yolo -v yolo -k apollo/modules "$PROCESS_DIR"/extracted_files >> "$PROCESS_LOG_FILE"
	mv apollo.csv "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_celllocation.kmz "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_ltecelllocation.kmz "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_ltecelllocationlocal.kmz "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_wifilocation.kmz "$PROCESS_DIR"/apollo
	mv routined_local_vehicle_parked_history.kmz "$PROCESS_DIR"/apollo 
    
	time_update
	echo -e "[*]\n[*]"    
	echo "[*] APOLLO completed at ${NOW}" | tee -a "$PROCESS_LOG_FILE"
  	echo -e "[*]\n[*]"

	time_update
	echo "[*] PROCESSING completed at ${NOW}" | tee -a "$PROCESS_LOG_FILE"
	echo -e "[*]\n[*]\n[*]\n[*]" 
    
	clear && dialog --title "iOS Triage" --msgbox "TRIAGE processing completed at ${NOW}" 6 40
	menu
}

menu () {
	tmpfile=`tmpfile 2>/dev/null` || tmpfile=/tmp/test$$ 
	trap "rm -f $tmpfile" 0 1 2 5 15 
	clear
	dialog --clear --backtitle "iOS Triage" --title "iOS Triage $VERSION" --menu "Choose an option:" 16 50 9 \
	1 "Collect basic information" \
	2 "Execute live commands" \
	3 "'private' folder acquisition" \
	4 "Full file system acquisition" \
	5 "Triage image, APOLLO, iLEAPP, sysdiagnose" \
	6 "Acquire a 'BFU relevant files' image" \
	7 "Execute 'find' commands" \
	8 "Help" \
	9 "Exit" 2> $tmpfile

	return=$?
	choice=`cat $tmpfile`

	case $return in
          0)
	    #echo "'$choice' chosen"
	    selected ;;
	  1)
	    # Cancel pressed
	    clear && exit 1 ;;
	255)
	    # ESC pressed
	    clear && exit 1 ;;
	esac
}

confirmation () {
	clear
	dialog --title "Confirmation" --yesno  "Option $choice selected. Are you sure to proceed? " 8 30
	answer=$(echo $?)

	#if no
	if [ "$answer" != "0" ]; then
	   menu
	fi
	clear
}

selected () {
	case $choice in
		1)
		  # info_collect
		  confirmation;
		  info_collect;
		  ;;
		2)
		  # live_commands
		  confirmation;
		  live_commands;
		  ;;
		3)
		  # private_image
		  confirmation;
		  private_image;
		  ;;
		4)
		  # full_image
		  confirmation;
		  full_image;
		  ;;
		5)
		  # process_relevant_files
		  if [ $process == 0 ];then
            menu;
          else    
            confirmation;
		    process_relevant_files;
          fi
		  ;;        
		6)
		  # bfu_relevant_image
		  confirmation;
		  bfu_relevant_image;
		  ;;
		7)
		  # find_commands
		  confirmation;
		  find_commands;
		  ;;
		8)
		  # help
          clear && dialog --title "iOS Triage" --msgbox "iOS Triage Script\n[ Version \"$VERSION\" ]\n\nThis script dumps information from an iOS Device where checkra1n has been installed\n\nDISCLAIMER: This script is just a PoC and must be used only on test devices\n\nOPTION 1\nThis option executes the 'ideviceninfo' tool to collect basic information\n\nOPTION 2\nThis option executes 14 live commands on the device. The execution should take about 15 seconds\n\nOPTION 3\nThis option creates a TAR file of '/private', excluding application Bundles and MobileAsset. When in BFU state, the execution should take about 10 to 15 minutes. When in AFU state, the amount of time depends on the total file size and can reach several hours. In our tests the average speed is about 25 GB per hour.\n\nOPTION 4\nThis option creates a TAR file of the full file system. When in BFU state, the execution should take about 30 minutes. When in AFU state, the amount of time depends on the total file size and can reach several hours. In our tests the average speed is about 25 GB per hour.\n\nOPTION 5\nThis option extract relevant files and parse them with APOLLO, iLEAPP and Sysdiagnose Scripts. The execution should take about 5 to 10 minutes.\n\nOPTION 6\nThis option extracts relevant files available BFU. The execution should take about 5 minutes.\n\nOPTION 7\nThis option executes 10 'find' commands to search for DOC/DOCX, XLS/XLSX, PPT/PPTX, PDF, TXT, HEIC, JPG, MOV, WhatsApp Contacts, WhatsApp Groups, Skype username, Twitter username and all files and folders in /private/var. The execution should take about 10 minutes, depending on the amount of files on the device" 60 60;
		  menu
		  ;;
		9)
		  # exit
		  clear;
		  exit 1;
		  ;;  
	esac
}

## main ##
check_device
check_ssh 
check_dependances
menu
