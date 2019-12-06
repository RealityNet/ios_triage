# ios_bfu_triage
Bash script to extract data from a "chekcra1ned" iOS device

Developed and tested on Mac OS X Mojave (10.14.6)

<b>Requirements</b>

- checkra1n (https://checkra.in/)
- libimobiledevice (https://www.libimobiledevice.org/)
- SSHPASS for Mac OS X (https://gist.github.com/arunoda/7790979)

<b>How to use it</b>

- checkra1n an iOS device
- Open a terminal and execute "iproxy 22 44"
- Open a new terminal and execute ssh root@localhost and add localhost to the list of known hosts
- Download the script in the folder where you want to save the extraction (i.e. Destkop)
- Make the script executable (chmod +x ios_bfu_triage.sh)
- Execute the script and follow the instructions

<b>Version 0.1 [5/12/2019]</b>
First release

<b>Version 0.2 [6/12/2019]</b>
Changed the output folder name to the device UDID instead of device NAME
