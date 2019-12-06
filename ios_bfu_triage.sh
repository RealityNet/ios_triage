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

echo "[*] iOS BFU Triage Script - version 0.2 - 6/12/2019"
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
SPATH=$UDID.$NOW

mkdir -p ${SPATH}
cat ${TMP_INFO} > ${SPATH}/${UDID}_info.txt
rm "${TMP_INFO}"

read -p "[*] Do you want to execute live commands (like date, sysctl, hostname, df, ifconfig, etc) on ${NAME}? (Y/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ${SPATH}/${UDID}_live
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] LIVE Acquisition started at ${NOW}" 
    echo "[*] LIVE Acquisition started at ${NOW}" >> ${SPATH}/${UDID}_live/${UDID}_live_log.txt
    echo "[*] Executing live commands"
    echo "[*] date"
    sshpass -p alpine ssh root@localhost "date" >> ${SPATH}/${UDID}_live/${UDID}_date.txt
    echo "[*] sysctl -a"
    sshpass -p alpine ssh root@localhost "sysctl -a" >> ${SPATH}/${UDID}_live/${UDID}_sysctl-a.txt
    echo "[*] hostname"
    sshpass -p alpine ssh root@localhost "hostname" >> ${SPATH}/${UDID}_live/${UDID}_hostname.txt
    echo "[*] uname -a"
    sshpass -p alpine ssh root@localhost "uname -a" >> ${SPATH}/${UDID}_live/${UDID}_uname-a.txt
    echo "[*] id"
    sshpass -p alpine ssh root@localhost "id" >> ${SPATH}/${UDID}_live/${UDID}_id.txt
    echo "[*] df"
    sshpass -p alpine ssh root@localhost "df" >> ${SPATH}/${UDID}_live/${UDID}_df.txt
    echo "[*] df -ah"
    sshpass -p alpine ssh root@localhost "df -ah" >> ${SPATH}/${UDID}_live/${UDID}_df-ah.txt
    echo "[*] ifconfig -a"
    sshpass -p alpine ssh root@localhost "ifconfig -a" >> ${SPATH}/${UDID}_live/${UDID}_ifconfig-a.txt
    echo "[*] netstat -an"
    sshpass -p alpine ssh root@localhost "netstat -an" >> ${SPATH}/${UDID}_live/${UDID}_netstat-an.txt
    echo "[*] mount"
    sshpass -p alpine ssh root@localhost "mount" >> ${SPATH}/${UDID}_live/${UDID}_mount.txt
    echo "[*] ps -ef"
    sshpass -p alpine ssh root@localhost "ps -ef" >> ${SPATH}/${UDID}_live/${UDID}_ps-ef.txt
    echo "[*] ps aux"
    sshpass -p alpine ssh root@localhost "ps aux" >> ${SPATH}/${UDID}_live/${UDID}_ps_aux.txt
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] LIVE Acquisition completed at ${NOW}"
    echo "[*] LIVE Acquisition completed at ${NOW}" >> ${SPATH}/${UDID}_live/${UDID}_live_log.txt
fi

read -p "[*] Do you want to create a triage image of the /private/ folder in '${SPATH}/${UDID}_acquisition/${UDID}.tar'? (Y/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ${SPATH}/${UDID}_acquisition
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] Triage image of /private/ started at ${NOW}" 
    echo "[*] Triage image of /private/ started at  ${NOW}" >> ${SPATH}/${UDID}_acquisition/${UDID}_acquisition_log.txt
    echo "[*] Executing 'tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset'" 
    sshpass -p alpine ssh root@localhost "tar -cf - /private --exclude=/private/var/containers/Bundle --exclude=/private/var/MobileAsset" > ${SPATH}/${UDID}_acquisition/${UDID}.tar 2>>${SPATH}/${UDID}_acquisition/${UDID}_acquisition_log.txt
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] Triage image of /private/ completed at ${NOW}" 
    echo "[*] Triage image of /private/ completed  ${NOW}" >> ${SPATH}/${UDID}_acquisition/${UDID}_acquisition_log.txt
    echo "[*] shasum of ${SPATH}/${UDID}.tar in progress"   
    echo "[*] shasum of ${SPATH}/${UDID}.tar in progress" >> ${SPATH}/${UDID}_acquisition/${UDID}_acquisition_log.txt    
    shasum ${SPATH}/${UDID}_acquisition/${UDID}.tar >> ${SPATH}/${UDID}_acquisition/${UDID}_acquisition_log.txt
fi

read -p "[*] Do you want to execute 'find /private' in ${NAME}? (Y/n) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ${SPATH}/${UDID}_find
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] find /private started at ${NOW}" 
    echo "[*] find /private started at ${NOW}" >> ${SPATH}/${UDID}_find/${UDID}_find.txt
    sshpass -p alpine ssh root@localhost "find /private" >> ${SPATH}/${UDID}_find/${UDID}_find.txt    
    NOW=$(date +"%Y_%m_%d_%H_%M_%S")
    echo "[*] find /private completed at ${NOW}" 
    echo "[*] find /private completed at ${NOW}" >> ${SPATH}/${UDID}_find/${UDID}_find.txt
fi
