# iOS Triage
Bash script to extract data from a "chekcra1ned" iOS device

Developed and tested on Mac OS X Mojave (10.14.6)

<b>Mandatory Requirements</b>

- checkra1n (https://checkra.in/)
- libimobiledevice (https://www.libimobiledevice.org/)
- SSHPASS for Mac OS X (https://gist.github.com/arunoda/7790979)
- dialog for Mac OS X (http://macappstore.org/dialog/)

<b>Optional Requirements</b>

- python3 (https://www.python.org/downloads/)
- sysdiagnose scripts (https://github.com/cheeky4n6monkey/iOS_sysdiagnose_forensic_scripts)
- APOLLO (https://github.com/mac4n6/APOLLO)
- iOS Mobile Installation Logs Parser (https://github.com/abrignoni/iOS-Mobile-Installation-Logs-Parser)

<b>How to use it</b>

- checkra1n an iOS device
- Open a terminal and execute "sudo iproxy 22 44"
- Open a new terminal and execute ssh root@localhost and add localhost to the list of known hosts
- Download the script in the folder where you want to save the extraction (i.e. Destkop)
- Make the script executable (chmod +x ios_bfu_triage.sh)
- Execute the script and follow the instructions

<b>Version 0.1 [5/12/2019]</b>
First release

<b>Version 0.2 [6/12/2019]</b>
Changed the output folder name to the device UDID instead of the device NAME

<b>Version 1.0 [23/12/2019]</b>
For detailed instructions read this:
Checkra1n Era - Ep 5 - Automating extraction and processing (aka "Marry Xmas!")
(https://blog.digital-forensics.it/2019/12/checkra1n-era-ep-5-automating.html)

<b>Version 2.0 [5/6/2020]</b>
- Improved direct extraction and processing with APOLLO, iLEAPP and sysdiagnose
- Improved "find" function



