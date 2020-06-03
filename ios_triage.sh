#!/bin/bash

# ios_bfu_triage
# Mattia Epifani && Giovanni Rattaro
# 2019122 V.1.0
#
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################
# MANDATORY REQUIREMENTS
#####################################################################
#
# - libimobiledevice
# - sshpass
# - dialog
#
#####################################################################
# OPTIONAL REQUIREMENTS
#####################################################################
#
# - python3
# - sysdiagnose scripts
# - APOLLO
# - MobileInstallation Logs Parser
#
#####################################################################
# VARIABLES
#####################################################################

# generic var
VERSION="1.0 - 20191221"

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
	FIND_LOG_FILE="${FIND_DIR}"/${NOW}_find_log.txt
	FIND_PRIVATE="${FIND_DIR}"/${NOW}_find_private.txt
	FIND_MAIL_ADDRESS="${FIND_DIR}"/${NOW}_find_mail_address.txt
	FIND_MAIL_PDF="${FIND_DIR}"/${NOW}_find_mail_pdf.txt
	FIND_MAIL_DOC="${FIND_DIR}"/${NOW}_find_mail_doc.txt
	FIND_MAIL_XLS="${FIND_DIR}"/${NOW}_find_mail_xls.txt
	FIND_WA_CONTACTS="${FIND_DIR}"/${NOW}_find_wa_contacts.txt
	FIND_WA_GROUPS="${FIND_DIR}"/${NOW}_find_wa_groups.txt

    # Directories for BFU relevant image
	TRIAGE_DIR="${SPATH}/${NOW}_bfu"
    TRIAGE_LOG_FILE="$TRIAGE_DIR/${NOW}_bfu.txt"

    # Directories for 'private' image
	ACQUISITION_DIR="${SPATH}/${NOW}_acquisition_private"
	ACQUISITION_LOG_FILE="${ACQUISITION_DIR}/${NOW}_acquisition_private_log.txt"
    
    # Directories for full file system image
	ACQUISITION_DIR_FULL="${SPATH}/${NOW}_acquisition_full"
	ACQUISITION_LOG_FILE_FULL="${ACQUISITION_DIR_FULL}/${NOW}_acquisition_full_log.txt"

    # Directories for extract and process
	PROCESS_DIR="${SPATH}/${NOW}_process"
	PROCESS_LOG_FILE="$PROCESS_DIR/${NOW}_process.txt"

}

check_device () {
	if [ "$(echo "$UDID" | grep -c found)" == "1" ];then
	   clear && dialog --title "ios bfu triage" --msgbox "NO DEVICE CONNECTED!" 5 24 && clear && exit
	fi
}

check_dependances () {
        TOOL="mib_parser.sql.py"
        if [ "$(command -v "$TOOL" | wc -l)" == "1" ]; then
            MIB_PARSER_SQL="python3 $(command -v "$TOOL")"
          else
            if [[ -f "./mib/$TOOL" ]]; then
                MIB_PARSER_SQL="python3 $TOOL"
              else
                clear && dialog --title "ios bfu triage" --msgbox "$TOOL NOT FOUND! 'Process relevant files' option not available" 6 45 && process=0 && menu
            fi
        fi

        TOOL="apollo.py"
        if [ "$(command -v "$TOOL" | wc -l)" == "1" ]; then
            APOLLO="python3 $(command -v "$TOOL")"
          else
            if [[ -f "./apollo/$TOOL" ]]; then
                APOLLO="python3 ./apollo/$TOOL"
              else
                clear && dialog --title "ios bfu triage" --msgbox "$TOOL NOT FOUND! 'Process relevant files' option not available" 6 45 && process=0 && menu
            fi
        fi

	for TOOL in sysdiagnose-mobileactivation.py sysdiagnose-mobilebackup.py sysdiagnose-wifi-icloud.py sysdiagnose-networkprefs.py sysdiagnose-networkinterfaces.py sysdiagnose-wifi-plist.py sysdiagnose-mobilecontainermanager.py sysdiagnose-appconduit.py sysdiagnose-wifi-net.py sysdiagnose-wifi-kml.py; do
    
	   toolvar=$(echo $TOOL | tr . _ | tr - _)

	   if [ "$(command -v "$TOOL" | wc -l)" == "0" ]; then
	           declare ${toolvar}="python3 $(command -v "$TOOL")"
	    else
	      if [[ -f "./sysdiagnose/$TOOL" ]]; then
		      declare ${toolvar}="python3 ./sysdiagnose/$TOOL"      
	       else
		 clear && dialog --title "ios bfu triage" --msgbox "$TOOL NOT FOUND! 'Process relevant files' option not available" 6 45 && process=0 && menu 
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
           clear && dialog --title "ios bfu triage" --yesno  "SSH IS NOT WORKING! \nVERIFY IF THE DEVICE IS JAILBROKEN AND IF IPROXY IS RUNNING! \n\nHowever are you going to collect device basic information?" 13 30
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

        dialog --title "ios bfu triage" --msgbox "\n
        [*] Dumping info from device: ${NAME}\n
        [*] Device UDID: ${UDID}\n
        [*] Device Type: ${TYPE}\n
        [*] Hardware Model: ${HWMODEL}\n
        [*] Product Type: ${PRODUCT}\n
        [*] iOS Version: ${IOS_VERSION}\n
        [*] Wi-Fi Mac Address: ${WIFI}\n\n" 14 70

        clear && dialog --title "ios bfu triage" --msgbox "DEVICE INFO acquisition completed" 5 40
        if [ "$JAILBREAK" != "NOK" ]; then
           menu
         else
           clear &&  exit
        fi
}

live_commands () {
	set_path
	mkdir -p "$LIVE_DIR"
    echo -e "[*]\n[*]"
	echo "[*] This option executes 14 live commands on the device. The executions should take about 15 seconds"
	echo -e "[*]\n[*]"
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
    
	clear && dialog --title "ios bfu triage" --msgbox "LIVE Acquisition completed at ${NOW}" 6 34
	menu
}

find_commands () {
	set_path
	mkdir -p "$FIND_DIR"
	echo -e "[*]\n[*]"
	echo "[*] This option executes 7 'find' commands. The execution should take about 5 to 10 minutes, depending on the amount of files"
	echo -e "[*]\n[*]"
    time_update
	echo "[*] find /private/var/mobile/Library/DataAccess -type d -name \"*IMAP-*\" started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Library/DataAccess -type d -name \"*IMAP-*\"" >> "$FIND_MAIL_ADDRESS"
	time_update
	echo "[*] find /private/var/mobile/Library/DataAccess -type d -name \"*IMAP-*\" completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
 	echo -e "[*]\n[*]"
	time_update
	echo "[*] find /private/var/mobile/Library/Mail -type f -name \"*.pdf\" started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Library/Mail -type f -name \"*.pdf\" -ls" >> "$FIND_MAIL_PDF"
	time_update
	echo "[*] find /private/var/mobile/Library/Mail -type f -name \"*.pdf\" completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
	echo -e "[*]\n[*]"
	time_update
	echo "[*] find /private/var/mobile/Library/Mail -type f -name \"*.doc*\" started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Library/Mail -type f -name \"*.doc*\" -ls" >> "$FIND_MAIL_DOC"
	time_update
	echo "[*] find /private/var/mobile/Library/Mail -type f -name \"*.doc*\" completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
  	echo -e "[*]\n[*]"  
	time_update
	echo "[*] find /private/var/mobile/Library/Mail -type f -name \"*.xls*\" started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Library/Mail -type f -name \"*.xls*\" -ls" >> "$FIND_MAIL_XLS"
	time_update
	echo "[*] find /private/var/mobile/Library/Mail -type f -name \"*.xls*\" completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
	echo -e "[*]\n[*]"
	time_update
	echo "[*] find /private/var/mobile/Containers -type d -name \"*@s.whatsapp.net*\" started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Containers -type d -name \"*@s.whatsapp.net*\"" >> "$FIND_WA_CONTACTS"
	time_update
	echo "[*] find /private/var/mobile/Containers -type d -name \"*@s.whatsapp.net*\" completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
 	echo -e "[*]\n[*]"   
	time_update
	echo "[*] find /private/var/mobile/Containers-type d -name \"*@g.us*\" started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var/mobile/Containers -type d -name \"*@g.us*\"" >> "$FIND_WA_GROUPS"
	time_update
	echo "[*] find /private/var/mobile/Containers -type d -name \"*@g.us*\" completed at ${NOW}" | tee -a "$FIND_LOG_FILE"
 	echo -e "[*]\n[*]"   
	time_update
	echo "[*] find /private/var started at ${NOW}" | tee -a "$FIND_LOG_FILE"
	$SSH_COMMAND "find /private/var -ls" >> "$FIND_PRIVATE" 2>/dev/null
	time_update
	echo "[*] find /private/var completed at ${NOW}" | tee -a "$FIND_LOG_FILE"  
	echo -e "[*]\n[*]"
    
	clear && dialog --title "ios bfu triage" --msgbox "FIND commands completed at ${NOW}" 6 40
	menu
}

bfu_relevant_image () {
	set_path
	mkdir -p "$TRIAGE_DIR"
	echo -e "[*]\n[*]"
	echo "[*] This option extracts relevant files available BFU and creates a TAR file." 
    echo "[*] The execution should take about 5 minutes."
	echo -e "[*]\n[*]"
	echo "[*] BFU RELEVANT image started at ${NOW}" | tee "$TRIAGE_LOG_FILE"
	echo -e "[*]\n[*]"		
	# Default directories creation
	mkdir -p "$TRIAGE_DIR"/extracted_files
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/containers
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/db
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/db/spindump
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/installd/Library/Logs
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/logs 
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/AggregateDictionary
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/AppConduit
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/ApplicationSync
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Caches
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Calendar
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/CallHistoryDB
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Containers
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs/mobileactivationd
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Preferences
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SpringBoard
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SMS    
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SyncedPreferences
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/UserNotifications 
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Voicemail
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/mobile/Media/iTunes_Control/iTunes
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/preferences/SystemConfiguration
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/wireless/Library/Databases
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/wireless/Library/Preferences
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Caches/locationd
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Lockdown
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Logs/MobileContainerManager
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/root/Library/MobileContainerManager
	mkdir -p "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Preferences

	echo "[*] Extracting /private/var/containers/Data" 
	$SCP_FOLDER_COMMAND/private/var/containers/Data "$TRIAGE_DIR"/extracted_files/private/var/containers >> "$TRIAGE_LOG_FILE" 2>&1	

	echo "[*] Extracting /private/var/containers/Shared" 
	$SCP_FOLDER_COMMAND/private/var/containers/Shared "$TRIAGE_DIR"/extracted_files/private/var/containers >> "$TRIAGE_LOG_FILE" 2>&1	

	echo "[*] Extracting /private/var/db/analyticsd" 
	$SCP_FOLDER_COMMAND/private/var/db/analyticsd "$TRIAGE_DIR"/extracted_files/private/var/db/ >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/db/dhcpd_leases" 
	$SCP_FILE_COMMAND/private/var/db/dhcpd_leases "$TRIAGE_DIR"/extracted_files/private/var/db/

	echo "[*] Extracting /private/var/db/dhcpclient/leases/" 
	$SCP_FOLDER_COMMAND/private/var/db/dhcpclient/leases/ "$TRIAGE_DIR"/extracted_files/private/var/db/dhcpclient/ >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/db/spindump/UUIDToBinaryLocations" 
	$SCP_FILE_COMMAND/private/var/db/spindump/UUIDToBinaryLocations "$TRIAGE_DIR"/extracted_files/private/var/db/spindump/
    
	echo "[*] Extracting /private/var/db/systemstats" 
	$SCP_FOLDER_COMMAND/private/var/db/systemstats "$TRIAGE_DIR"/extracted_files/private/var/db/ >> "$TRIAGE_LOG_FILE" 2>&1
	
	echo "[*] Extracting /private/var/installd/Library/Logs/MobileInstallation/" 
	$SCP_FOLDER_COMMAND/private/var/installd/Library/Logs/MobileInstallation/ "$TRIAGE_DIR"/extracted_files/private/var/installd/Library/Logs/ >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/installd/Library/MobileInstallation/" 
	$SCP_FOLDER_COMMAND/private/var/installd/Library/MobileInstallation/ "$TRIAGE_DIR"/extracted_files/private/var/installd/Library/ >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/log/" 
	$SCP_FOLDER_COMMAND/private/var/log/ "$TRIAGE_DIR"/extracted_files/private/var/ >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/logs/" 
	$SCP_FOLDER_COMMAND/private/var/logs/ "$TRIAGE_DIR"/extracted_files/private/var/ >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Accounts/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Accounts "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1 
    
	echo "[*] Extracting /private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb* "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/AggregateDictionary/

	echo "[*] Extracting /private/var/mobile/Library/AppConduit/AvailableApps.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AppConduit/AvailableApps.plist "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/AppConduit/AvailableApps.plist
   
	echo "[*] Extracting /private/var/mobile/Library/AppConduit/AvailableCompanionApps.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AppConduit/AvailableCompanionApps.plist "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/AppConduit/AvailableCompanionApps.plist

	echo "[*] Extracting /private/var/mobile/Library/ApplicationSync/AssetSortOrder.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/ApplicationSync/AssetSortOrder.plist "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/ApplicationSync/AssetSortOrder.plist

	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.mobilesms.compose/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Caches/com.apple.mobilesms.compose "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Caches >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.MobileSMS/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Caches/com.apple.MobileSMS "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Caches >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Caches/com.apple.NanoTimeKit/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Caches/com.apple.NanoTimeKit "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Caches >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Calendar/Notifications.Calendar.Protected"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Calendar/Notifications.Calendar.Protected "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Calendar/Notifications.Calendar.Protected

	echo "[*] Extracting /private/var/mobile/Library/CallHistoryDB/CallHistoryTemp.storedata"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CallHistoryDB/CallHistoryTemp.storedata* "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/CallHistoryDB/

	echo "[*] Extracting /private/var/mobile/Library/com.apple.itunesstored/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/com.apple.itunesstored/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/DataAccess/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/DataAccess/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/DeviceRegistry/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/DeviceRegistry/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/DeviceRegistry.state/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/DeviceRegistry.state/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/FrontBoard/"    
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/FrontBoard/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/AppConduit/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/AppConduit "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/AppleSupport/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/AppleSupport "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/Logs/com.apple.itunesstored/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/com.apple.itunesstored "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/CrashReporter/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/CrashReporter "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.log.0" 
	$SCP_FILE_COMMAND/private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.log.0 "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs/mobileactivationd/mobileactivationd.log.0
    
	echo "[*] Extracting /private/var/mobile/Library/Logs/NotificationProxy/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/NotificationProxy "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Logs >> "$TRIAGE_LOG_FILE" 2>&1

	echo "[*] Extracting /private/var/mobile/library/Preferences/"    
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Preferences/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/ >> "$TRIAGE_LOG_FILE" 2>&1
    
	echo "[*] Extracting /private/var/mobile/Library/SMS/sms-temp.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SMS/sms-temp.db* "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SMS/
    
	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/IconState.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/IconState.plist "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SpringBoard
	
	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/DesiredIconState.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/DesiredIconState.plist "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SpringBoard

	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/TodayViewArchive.plist"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/TodayViewArchive.plist "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SpringBoard
	
	echo "[*] Extracting /private/var/mobile/Library/SpringBoard/LockBackgroundThumbnail.jpg"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SpringBoard/LockBackgroundThumbnail.jpg "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/SpringBoard  

	echo "[*] Extracting /private/var/mobile/Library/Synced Preferences/" 
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/SyncedPreferences/ "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/ >> "$TRIAGE_LOG_FILE" 2>&1 
    
	echo "[*] Extracting /private/var/mobile/Library/TCC/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/TCC "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/UserNotifications/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/UserNotifications "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1 
    
	echo "[*] Extracting /private/var/mobile/Library/UserConfigurationProfiles/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/UserConfigurationProfiles "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library >> "$TRIAGE_LOG_FILE" 2>&1 

	echo "[*] Extracting /private/var/mobile/Library/Voicemail/voicemail.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Voicemail/voicemail.db "$TRIAGE_DIR"/extracted_files/private/var/mobile/Library/Voicemail
    
	echo "[*] Extracting /private/var/mobile/Library/Media/iTunes_Control/iTunes/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Media/iTunes_Control/iTunes "$TRIAGE_DIR"/extracted_files/private/var/mobile/Media/iTunes_Control >> "$TRIAGE_LOG_FILE" 2>&1   

	echo "[*] Extracting /private/var/preferences/"
	$SCP_FOLDER_COMMAND/private/var/preferences/ "$TRIAGE_DIR"/extracted_files/private/var/ >> "$TRIAGE_LOG_FILE" 2>&1   

	echo "[*] Extracting /private/var/root/Library/Caches/locationd/cache.plist"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache.plist "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Caches/locationd

	echo "[*] Extracting /private/var/root/Library/Caches/locationd/clients.plist"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/clients.plist "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Caches/locationd    

	echo "[*] Extracting /private/var/root/Library/Preferences/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Preferences "$TRIAGE_DIR"/extracted_files/private/var/root/Library/ >> "$TRIAGE_LOG_FILE" 2>&1  
    
	echo "[*] Extracting /private/var/root/Library/Lockdown/"    
	$SCP_FOLDER_COMMAND/private/var/root/Library/Lockdown/ "$TRIAGE_DIR"/extracted_files/private/var/root/Library/
    
	echo "[*] Extracting /private/var/root/Library/Logs/MobileContainerManager/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Logs/MobileContainerManager/ "$TRIAGE_DIR"/extracted_files/private/var/root/Library/Logs/ >> "$TRIAGE_LOG_FILE" 2>&1   
	echo "[*] Extracting /private/var/root/Library/MobileContainerManager/containers.sqlite3"
	$SCP_FILE_COMMAND/private/var/root/Library/MobileContainerManager/containers.sqlite3* "$TRIAGE_DIR"/extracted_files/private/var/root/Library/MobileContainerManager/
    
	echo "[*] Extracting /private/var/wireless/Library/Databases/CellularUsage.db"  
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/CellularUsage.db* "$TRIAGE_DIR"/extracted_files/private/var/wireless/Library/Databases

	echo "[*] Extracting /private/var/wireless/Library/Databases/DataUsage.sqlite"
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/DataUsage.sqlite* "$TRIAGE_DIR"/extracted_files/private/var/wireless/Library/Databases

	echo "[*] Extracting /private/var/wireless/Library/Preferences/"  
	$SCP_FOLDER_COMMAND/private/var/wireless/Library/Preferences/ "$TRIAGE_DIR"/extracted_files/private/var/wireless/Library

    echo -e "[*]\n[*]"    
	echo "[*] Creating TAR file" 
	tar -cvf "$TRIAGE_DIR"/${UDID}_triage_bfu.tar -C "$TRIAGE_DIR"/extracted_files private >> "$TRIAGE_LOG_FILE" 2>/dev/null
	time_update
    echo -e "[*]\n[*]"    
    echo "[*] BFU RELEVANT  image completed at ${NOW}" | tee -a "$TRIAGE_LOG_FILE"
	echo -e "[*]\n[*]"
	echo "[*] Calculating SHA hash" 
	shasum ${TRIAGE_DIR}/${UDID}_triage_bfu.tar >> "$TRIAGE_LOG_FILE" 2>&1

	clear && dialog --title "ios bfu triage" --msgbox "TRIAGE BFU image completed at ${NOW}" 6 40
	menu    
}

private_image () {
	set_path
	mkdir -p "$ACQUISITION_DIR"
	echo -e "[*]\n[*]"
	echo "[*] This option creates a TAR file of '/private', excluding application Bundles and MobileAsset." 
    echo "[*] When in BFU state, the execution should take about 10 to 15 minutes."
    echo "[*] When in AFU state, the amount of time depends on the total file size and can reach several hours."
    echo "[*] In our tests the average speed is about 25 GB per hour"
	echo -e "[*]\n[*]"    
	echo "[*] TRIAGE image of /private/ started at  ${NOW}" | tee "$ACQUISITION_LOG_FILE"
	echo -e "[*]\n[*]"      
	echo "[*] Executing 'tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset'" 
	$SSH_COMMAND "tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset" > "${ACQUISITION_DIR}"/${UDID}_private.tar 2>>"$ACQUISITION_LOG_FILE" 		
	echo -e "[*]\n[*]" 
	time_update	
	echo "[*] TRIAGE image of /private/ completed at ${NOW}" | tee -a "$ACQUISITION_LOG_FILE"
	echo -e "[*]\n[*]\n"
	echo "[*] sha1sum of ${SPATH}/${UDID}_private.tar in progress" | tee -a "$ACQUISITION_LOG_FILE"
	shasum "${ACQUISITION_DIR}"/${UDID}_private.tar | tee -a "$ACQUISITION_LOG_FILE"    
    
	clear && dialog --title "ios bfu triage" --msgbox "TRIAGE image of /private/ completed at ${NOW}" 6 40
	menu
}

full_image () {
 	set_path
	mkdir -p "$ACQUISITION_DIR_FULL"
	echo -e "[*]\n[*]"
	echo "[*] This option creates a TAR file of the full file system." 
    echo "[*] When in BFU state, the execution should take about 30 minutes."
    echo "[*] When in AFU state, the amount of time depends on the total file size and can reach several hours."
    echo "[*] In our tests the average speed is about 25 GB per hour"
	echo -e "[*]\n[*]"      
	echo "[*] FULL image started at ${NOW}" | tee "$ACQUISITION_LOG_FILE_FULL"
	echo -e "[*]\n[*]"  
	echo "[*] Executing 'tar -cf - /'" 
	$SSH_COMMAND "tar -cf - /" > "${ACQUISITION_DIR_FULL}"/${UDID}_full.tar 2>>"$ACQUISITION_LOG_FILE_FULL"
	echo -e "[*]\n[*]" 
	time_update
	echo "[*] FULL image completed  ${NOW}" | tee -a "$ACQUISITION_LOG_FILE_FULL"
	echo -e "[*]\n[*]" 
	echo "[*] sha1sum of ${SPATH}/${UDID}_full.tar in progress" | tee -a "$ACQUISITION_LOG_FILE_FULL"
	shasum "${ACQUISITION_DIR_FULL}"/${UDID}_full.tar | tee -a "$ACQUISITION_LOG_FILE_FULL"

	clear && dialog --title "ios bfu triage" --msgbox "FULL image completed at ${NOW}" 6 40
	menu
}

process_relevant_files () {
	set_path
	mkdir -p "$PROCESS_DIR"
	echo -e "[*]\n[*]"
	echo "[*] This option extracts relevant files and parse them with Sysdiagnose scripts, Mobile Installation Log Parser and APOLLO." 
    echo "[*] The execution should take about 5 to 10 minutes."
	echo -e "[*]\n[*]"       
	echo "[*] Extraction and processing started at ${NOW}" | tee "$PROCESS_LOG_FILE"
	echo -e "[*]\n[*]" | tee "$PROCESS_LOG_FILE"
    echo "[*] Extracting data for 'sysdiagnose' scripts"
	echo -e "[*]\n[*]" | tee "$PROCESS_LOG_FILE"
    
	mkdir -p "sysdiagnose/temp"

    echo "[*] Extracting /private/var/mobile/Library/Logs/AppConduit/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/AppConduit/ sysdiagnose/temp

	echo "[*] Extracting /private/var/mobile/Library/Logs/CrashReporter/WiFi"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/CrashReporter/WiFi/ sysdiagnose/temp

	echo "[*] Extracting /private/var/mobile/Library/Logs/mobileactivationd/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/Logs/mobileactivationd/ sysdiagnose/temp

	echo "[*] Extracting /private/var/mobile/Library/SyncedPreferences/"
	$SCP_FOLDER_COMMAND/private/var/mobile/Library/SyncedPreferences/ sysdiagnose/temp

	echo "[*] Extracting /private/var/preferences/"
	$SCP_FOLDER_COMMAND/private/var/preferences/ sysdiagnose/temp
    
	echo "[*] Extracting /private/var/root/Library/Preferences/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Preferences sysdiagnose/temp
    
	echo "[*] Extracting /private/var/root/Library/Logs/MobileContainerManager/" 
	$SCP_FOLDER_COMMAND/private/var/root/Library/Logs/MobileContainerManager/ sysdiagnose/temp
    
	mkdir -p "$PROCESS_DIR"/sysdiagnose
	echo -e "[*]\n[*]"     
	echo "[*] Executing sysdiagnose scripts" 
    
	echo -e "[*]\n[*]"         
	echo "[*] Processing com.apple.wifi.plist" 
    $sysdiagnose_wifi_plist_py_exec -i sysdiagnose/temp/preferences/SystemConfiguration/com.apple.wifi.plist -t > "$PROCESS_DIR"/sysdiagnose/com.apple.wifi.plist.txt
	mv sysdiagnose-wifi-plist-output.TSV "$PROCESS_DIR"/sysdiagnose/com.apple.wifi.plist.tsv
	
	echo "[*] Processing NetworkInterfaces.plist" 
    $sysdiagnose_networkinterfaces_py_exec -i sysdiagnose/temp/preferences/SystemConfiguration/NetworkInterfaces.plist > "$PROCESS_DIR"/sysdiagnose/NetworkInterfaces.txt
	
	echo "[*] Processing Network preferences.plist" 
    $sysdiagnose_networkprefs_py_exec -i sysdiagnose/temp/preferences/SystemConfiguration/preferences.plist > "$PROCESS_DIR"/sysdiagnose/NetworkPreferences.txt
	
	echo "[*] Processing com.apple.wifid.plist" 
    $sysdiagnose_wifi_icloud_py_exec -i sysdiagnose/temp/SyncedPreferences/com.apple.wifid.plist -t > "$PROCESS_DIR"/sysdiagnose/com.apple.wifid.plist.txt
	mv sysdiagnose-wifi-icloud-output.TSV "$PROCESS_DIR"/sysdiagnose/com.apple.wifid.plist.tsv
	
	echo "[*] Processing com.apple.MobileBackup.plist" 
    $sysdiagnose_mobilebackup_py_exec -i sysdiagnose/temp/Preferences/com.apple.MobileBackup.plist > "$PROCESS_DIR"/sysdiagnose/com.apple.MobileBackup.plist.txt
    
	echo "[*] Processing Mobile Activation logs" 
	cat sysdiagnose/temp/mobileactivationd/mobileactivationd.* > sysdiagnose/mobileactivationd.log
    $sysdiagnose_mobileactivation_py_exec -i sysdiagnose/mobileactivationd.log > "$PROCESS_DIR"/sysdiagnose/mobileactivationd.txt
	rm sysdiagnose/mobileactivationd.log
	
	echo "[*] Processing Mobile Container Manager logs"
	cat sysdiagnose/temp/MobileContainerManager/containermanagerd.log.* > sysdiagnose/containermanagerd.log
    $sysdiagnose_mobilecontainermanager_py_exec -i sysdiagnose/containermanagerd.log > "$PROCESS_DIR"/sysdiagnose/containermanagerd.txt
	rm sysdiagnose/containermanagerd.log
	
	echo "[*] Processing AppConduit logs"
	cat sysdiagnose/temp/AppConduit/AppConduit.log.* > sysdiagnose/AppConduit.log
    $sysdiagnose_appconduit_py_exec -i sysdiagnose/AppConduit.log > "$PROCESS_DIR"/sysdiagnose/AppConduit.log.txt
	rm sysdiagnose/AppConduit.log
    
	echo "[*] Processing WiFiManager logs"
	cat sysdiagnose/temp/WiFi/WiFiManager/* > sysdiagnose/wifi.log
    $sysdiagnose_wifi_net_py_exec -i sysdiagnose/wifi.log >> "$PROCESS_LOG_FILE"
	$sysdiagnose_wifi_kml_py_exec -i sysdiagnose/wifi.log >> "$PROCESS_LOG_FILE"   
	rm sysdiagnose/wifi.log
	mv wifi-buf-net_alreadyattached.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_alreadyattached.tsv
	mv wifi-buf-net_bgscan.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_bgscan.tsv
	mv wifi-buf-net_channels.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_channels.tsv
	mv wifi-buf-net_filtered.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_filtered.tsv
	mv wifi-buf-net_mru.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_mru.tsv
	mv wifi-buf-net_ppmattached.TSV "$PROCESS_DIR"/sysdiagnose/wifi_buf_net_ppmattached.tsv
	mv wifi-buf-locations.kml "$PROCESS_DIR"/sysdiagnose/wifi_buf_locations.kml

	rm -r "sysdiagnose/temp"
	echo -e "[*]\n[*]"
	echo "[*] Extracting data for Mobile Installation Logs Parser" 
 	echo -e "[*]\n[*]"   
	echo "[*] Extracting Mobile Installation Logs" 
	$SCP_FILE_COMMAND/private/var/installd/Library/Logs/MobileInstallation/* mib
	echo -e "[*]\n[*]"     
	echo "[*] Processing Mobile Installation Logs" 
	echo -e "[*]\n[*]"    
	cd mib
	$MIB_PARSER_SQL
	cd ..

	mkdir -p "$PROCESS_DIR"/mib

	mv mib/Apps_Historical "$PROCESS_DIR"/mib
	mv mib/Apps_State "$PROCESS_DIR"/mib
	mv mib/System_State "$PROCESS_DIR"/mib
	mv mib/mib.db "$PROCESS_DIR"/mib
	rm mib/mobile_installation.*

	echo -e "\n[*]\n[*]"
	echo "[*] Extracting databases for APOLLO"
	echo -e "[*]\n[*]"
	mkdir -p "$PROCESS_DIR"/apollo
	mkdir -p "apollo/temp"
    
	echo "[*] Extracting DataUsage.sqlite"
	$SCP_FILE_COMMAND/private/var/wireless/Library/Databases/DataUsage.sqlite* apollo/temp/

	echo "[*] Extracting ADDataStore.sqlitedb"
	$SCP_FILE_COMMAND/private/var/mobile/Library/AggregateDictionary/ADDataStore.sqlitedb* apollo/temp/

	echo "[*] Extracting CallHistory.storedata"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CallHistoryDB/CallHistory.storedata* apollo/temp/

	echo "[*] Extracting sms.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/SMS/sms.db* apollo/temp/

	echo "[*] Extracting interactionC.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CoreDuet/People/interactionC.db* apollo/temp/

	echo "[*] Extracting healthdb_secure.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Health/healthdb_secure.sqlite* apollo/temp/

	echo "[*] Extracting knowledgeC.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/CoreDuet/Knowledge/knowledgeC.db* apollo/temp/

	echo "[*] Extracting cache_encryptedA.db"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache_encryptedA.db* apollo/temp/

	echo "[*] Extracting cache_encryptedB.db"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache_encryptedB.db* apollo/temp/

	echo "[*] Extracting cache_encryptedC.db"
	$SCP_FILE_COMMAND/private/var/root/Library/Caches/locationd/cache_encryptedC.db* apollo/temp/

	echo "[*] Extracting netusage.sqlite"
	$SCP_FILE_COMMAND/private/var/networkd/netusage* apollo/temp/

	echo "[*] Extracting passes23.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Passes/passes23.sqlite* apollo/temp/

	echo "[*] Extracting query_predictions.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Suggestions/query_predictions.db* apollo/temp/

	echo "[*] Extracting Local.sqlite"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Caches/com.apple.routined/Local.sqlite* apollo/temp/

	echo "[*] Extracting History.db"
	$SCP_FILE_COMMAND/private/var/mobile/Library/Safari/History.db* apollo/temp/
 	echo -e "[*]\n[*]"     
	echo "[*] Executing APOLLO" 
	echo -e "[*]\n[*]"
	$APOLLO -o csv -p yolo -v yolo -k apollo/modules apollo/temp >> "$PROCESS_LOG_FILE"
	mv apollo.csv "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_celllocation.kmz "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_ltecelllocation.kmz "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_ltecelllocationlocal.kmz "$PROCESS_DIR"/apollo
	mv locationd_cacheencryptedAB_wifilocation.kmz "$PROCESS_DIR"/apollo
	mv routined_local_vehicle_parked_history.kmz "$PROCESS_DIR"/apollo    
	rm -r "apollo/temp"

	echo -e "[*]\n[*]"
	clear && dialog --title "ios bfu triage" --msgbox "Extraction and processing completed at ${NOW}" 6 40
	menu
}

menu () {
	tmpfile=`tmpfile 2>/dev/null` || tmpfile=/tmp/test$$ 
	trap "rm -f $tmpfile" 0 1 2 5 15 
	clear
	dialog --clear --backtitle "iOS BFU triage" --title "iOS BFU triage $VERSION" --menu "Choose an option:" 16 45 9 \
	1 "Collect basic information" \
	2 "Execute live commands" \
	3 "Execute 'find' commands" \
	4 "Acquire a 'BFU relevant files' image" \
	5 "Acquire a triage image" \
	6 "Acquire a full image" \
	7 "Extract and process relevant files" \
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
		  # find_commands
		  confirmation;
		  find_commands;
		  ;;
		4)
		  # bfu_relevant_image
		  confirmation;
		  bfu_relevant_image;
		  ;;
		5)
		  # image_triage
		  confirmation;
		  private_image;
		  ;;
		6)
		  # full_image
		  confirmation;
		  full_image;
		  ;;
		7)
		  # process_relevant_files
		  if [ $process == 0 ];then
            menu;
          else    
            confirmation;
		    process_relevant_files;
          fi
		  ;;
		8)
		  # help
          clear && dialog --title "ios bfu triage" --msgbox "iOS BFU Triage Script\n[ Version \"$VERSION\" ]\n\nThis script dumps information from an iOS Device where checkra1n has been installed\n\nDISCLAIMER: This script is just a PoC and must be used only on test devices\n\nOPTION 1\nThis option executes the 'ideviceninfo' tool to collect basic information\n\nOPTION 2\nThis option executes 14 live commands on the device. The execution should take about 15 seconds\n\nOPTION 3\nThis option executes 7 'find' commands. The execution should take about 10 minutes, depending on the amount of files on the device\n\nOPTION 4\nThis option extracts relevant files available BFU. The execution should take about 5 minutes.\n\nOPTION 5\nThis option creates a TAR file of '/private', excluding application Bundles and MobileAsset. When in BFU state, the execution should take about 10 to 15 minutes. When in AFU state, the amount of time depends on the total file size and can reach several hours. In our tests the average speed is about 25 GB per hour. \n\nOPTION 6\nThis option creates a TAR file of the full file system. When in BFU state, the execution should take about 30 minutes. When in AFU state, the amount of time depends on the total file size and can reach several hours. In our tests the average speed is about 25 GB per hour.\n\nOPTION 7\nThis option extract relevant files and parse them with Sysdiagnose scripts, Mobile Installation Log Parser, APOLLO. The execution should take about 5 to 10 minutes." 60 60;
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
