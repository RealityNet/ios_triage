#!/bin/bash  

NAME=$(ideviceinfo -s -k DeviceName)
TYPE=$(ideviceinfo -s -k DeviceClass)
UDID=$(ideviceinfo -s -k UniqueDeviceID)
HWMODEL=$(ideviceinfo -s -k HardwareModel)
PRODUCT=$(ideviceinfo -s -k ProductType)
IOS_VERSION=$(ideviceinfo -s -k ProductVersion)
WIFI=$(ideviceinfo -s -k WiFiAddress)
TMP_INFO=$(mktemp)

clear

echo "[*] iOS BFU Triage Script - version 0.1 - 5/12/2019"
echo "[*] This script dumps information from an iOS Device where checkra1n was installed"
echo "[*] This script requires libimobiledevice (iproxy and ideviceinfo) and SSHPASS"
echo "[*] DISCLAIMER: This script is a PoC and must be used only on test devices"
echo "[*]" | tee ${TMP_INFO}
echo "[*] Dumping info from device ${NAME}" | tee -a ${TMP_INFO}
echo "[*] Device UDID: ${UDID}" | tee -a ${TMP_INFO}
echo "[*] Device Type: ${TYPE}" | tee -a ${TMP_INFO}
echo "[*] Hardware Model: ${HWMODEL}" | tee -a ${TMP_INFO}
echo "[*] Product Type: ${PRODUCT}" | tee -a ${TMP_INFO}
echo "[*] iOS Version: ${IOS_VERSION}" | tee -a ${TMP_INFO}
echo "[*] Wi-Fi Mac Address: ${WIFI}" | tee -a ${TMP_INFO}
echo "[*]" | tee -a ${TMP_INFO}

NOW=$(date +"%Y_%m_%d_%H_%M_%S")
SPATH=$NAME.$NOW

mkdir -p ${SPATH}
cat ${TMP_INFO} > ${SPATH}/${NAME}_info.txt
rm "${TMP_INFO}"

read -p "[*] Do you want to execute live commands (like date, sysctl, hostname, df, ifconfig, etc) on ${NAME}? (Y/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ${SPATH}/${NAME}_live
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] LIVE Acquisition started at ${NOW}" 
    echo "[*] LIVE Acquisition started at ${NOW}" >> ${SPATH}/${NAME}_live/${NAME}_live_log.txt
    echo "[*] Executing live commands"
    echo "[*] date"
    sshpass -p alpine ssh root@localhost "date" >> ${SPATH}/${NAME}_live/${NAME}_date.txt
    echo "[*] sysctl -a"
    sshpass -p alpine ssh root@localhost "sysctl -a" >> ${SPATH}/${NAME}_live/${NAME}_sysctl-a.txt
    echo "[*] hostname"
    sshpass -p alpine ssh root@localhost "hostname" >> ${SPATH}/${NAME}_live/${NAME}_hostname.txt
    echo "[*] uname -a"
    sshpass -p alpine ssh root@localhost "uname -a" >> ${SPATH}/${NAME}_live/${NAME}_uname-a.txt
    echo "[*] id"
    sshpass -p alpine ssh root@localhost "id" >> ${SPATH}/${NAME}_live/${NAME}_id.txt
    echo "[*] df"
    sshpass -p alpine ssh root@localhost "df" >> ${SPATH}/${NAME}_live/${NAME}_df.txt
    echo "[*] df -ah"
    sshpass -p alpine ssh root@localhost "df -ah" >> ${SPATH}/${NAME}_live/${NAME}_df-ah.txt
    echo "[*] ifconfig -a"
    sshpass -p alpine ssh root@localhost "ifconfig -a" >> ${SPATH}/${NAME}_live/${NAME}_ifconfig-a.txt
    echo "[*] netstat -an"
    sshpass -p alpine ssh root@localhost "netstat -an" >> ${SPATH}/${NAME}_live/${NAME}_netstat-an.txt
    echo "[*] mount"
    sshpass -p alpine ssh root@localhost "mount" >> ${SPATH}/${NAME}_live/${NAME}_mount.txt
    echo "[*] ps -ef"
    sshpass -p alpine ssh root@localhost "ps -ef" >> ${SPATH}/${NAME}_live/${NAME}_ps-ef.txt
    echo "[*] ps aux"
    sshpass -p alpine ssh root@localhost "ps aux" >> ${SPATH}/${NAME}_live/${NAME}_ps_aux.txt
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] LIVE Acquisition completed at ${NOW}"
    echo "[*] LIVE Acquisition completed at ${NOW}" >> ${SPATH}/${NAME}_live/${NAME}_live_log.txt
fi

read -p "[*] Do you want to create a triage image of the /private/ folder in '${SPATH}/${NAME}_acquisition/${NAME}.tar'? (Y/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ${SPATH}/${NAME}_acquisition
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] Triage image of /private/ started at ${NOW}" 
    echo "[*] Triage image of /private/ started at  ${NOW}" >> ${SPATH}/${NAME}_acquisition/${NAME}_acquisition_log.txt
    echo "[*] Executing 'tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset'" 
    sshpass -p alpine ssh root@localhost "tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset" > ${SPATH}/${NAME}_acquisition/${NAME}.tar 2>>${SPATH}/${NAME}_acquisition/${NAME}_acquisition_log.txt
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] Triage image of /private/ completed at ${NOW}" 
    echo "[*] Triage image of /private/ completed  ${NOW}" >> ${SPATH}/${NAME}_acquisition/${NAME}_acquisition_log.txt
    echo "[*] shasum of ${SPATH}/${NAME}.tar in progress"   
    echo "[*] shasum of ${SPATH}/${NAME}.tar in progress" >> ${SPATH}/${NAME}_acquisition/${NAME}_acquisition_log.txt    
    shasum ${SPATH}/${NAME}_acquisition/${NAME}.tar >> ${SPATH}/${NAME}_acquisition/${NAME}_acquisition_log.txt
fi

read -p "[*] Do you want to execute 'find /private' in ${NAME}? (Y/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ${SPATH}/${NAME}_find
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] find /private started at ${NOW}" 
    echo "[*] find /private started at ${NOW}" >> ${SPATH}/${NAME}_find/${NAME}_find.txt
    sshpass -p alpine ssh root@localhost "find /private" >> ${SPATH}/${NAME}_find/${NAME}_find.txt    
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] find /private completed at ${NOW}" 
    echo "[*] find /private completed at ${NOW}" >> ${SPATH}/${NAME}_find/${NAME}_find.txt
fi