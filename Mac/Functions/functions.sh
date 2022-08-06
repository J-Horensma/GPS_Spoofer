#!/bin/bash
#GPS Spoofer functions
#By: Joel Horensma
#
#
####################################
#CHECK IF REQUIREMENTS ARE INSTALLED
####################################
function checkRequirements() {
while read -r LINE; do
if command -v ${LINE} >/dev/null 2>&1;then
printf "${LINE} is \x1B[32mINSTALLED\x1B[0m \xE2\x9C\x94 \n"
sleep 0.1
elif ! command -v ${LINE} >/dev/null 2>&1;then
printf "${LINE} is \x1B[31mNOT INSTALLED!\x1B[0m \xE2\x9D\x8C \n"
printf "Please install ${LINE} \n"
echo "Exiting..."
exit
fi;done < Requirements/requirements.txt
}


#########################
#CHECK DEVICE CONNECTION
#########################
function checkDeviceConnection() {
DEVICE_UDID=$(idevice_id -l | sed -n '1p')
DEVICE_PAIR_STATUS=$(idevicepair validate)
    clear
    #CHECK PAIR STATUS
    if [[ ${DEVICE_PAIR_STATUS} == "No device found." ]];then
    #IF DEVICE IS NOT CONNECTED
    printf "Status: \x1B[31mNOT CONNECTED!\x1B[0m \xE2\x9D\x8C \n"
    printf "Please connect the device, to the computer, VIA USB cable. \n\n"
    sleep 1
    checkDeviceConnection
    elif [[ ${DEVICE_PAIR_STATUS} == "ERROR: Could not validate with device ${DEVICE_UDID} because a passcode is set. Please enter the passcode on the device and retry." ]];then
    #IF DEVICE IS LOCKED
    printf "Status: \x1B[31mNOT CONNECTED!\x1B[0m \xE2\x9D\x8C \n"
    echo "Please unlock the device, to connect it to the computer."
    checkDeviceConnection
    elif [[ ${DEVICE_PAIR_STATUS} == "ERROR: Please accept the trust dialog on the screen of device ${DEVICE_UDID}, then attempt to pair again." ]];then
    #IF DEVICE HAS NOT TRUSTED THE COMPUTER
    printf "Status: \x1B[31mNOT CONNECTED!\x1B[0m \xE2\x9D\x8C \n"
    echo "Please accept the trust dialog, on the screen."
    checkDeviceConnection
    elif [[ ${DEVICE_PAIR_STATUS} == "ERROR: Device ${DEVICE_UDID} said that the user denied the trust dialog." ]];then
    #IF DEVICE PAIRING WAS DENIED
    printf "\x1B[31mNOT CONNECTED!\x1B[0m \xE2\x9D\x8C \n"
    printf "Pairing permission was denied, on the device. \n"
    printf "Please restart the device. \n"
    checkDeviceConnection
    else
    #IF DEVICE IS PAIRED WITH THE COMPUTER
    DEVICE_TYPE=$(ideviceinfo -u ${DEVICE_UDID} | grep "ProductName:" | awk '{printf $2}')
    DEVICE_OS_VERSION=$(ideviceinfo -u ${DEVICE_UDID} -k ProductVersion)
    printf "Status: \x1B[32mCONNECTED\x1B[0m \xE2\x9C\x94 \n\n"
    fi
    }


    ###############################################################
    #CHECK IF DEVICE DEVELOPER DISK IMAGE IS DOWNLOADED AND MOUNTED
    ###############################################################
    function checkDeveloperDiskImageMounted() {
    if [ -d "Disk_Images/${DEVICE_TYPE}/${DEVICE_OS_VERSION}" ];then
    #IF DEVELOPER DISK IMAGE IS ALREADY DOWNLOADED
    DOWNLOAD_STATUS=1
    else
    #IF DEVELOPER DISK IMAGE IS NOT DOWNLOADED
    printf "No developer disk image downloaded for version: ${DEVICE_TYPE} ${DEVICE_OS_VERSION} \xE2\x9D\x8C \n"
    printf "Downloading developer disk image for: ${DEVICE_TYPE} ${DEVICE_OS_VERSION}... \n\n"
    sleep 0.1
    DOWNLOAD_STATUS=$(wget https://github.com/mspvirajpatel/Xcode_Developer_Disk_Images/releases/download/${DEVICE_OS_VERSION}/${DEVICE_OS_VERSION}.zip && echo $?)
    sleep 1
    fi


    if [[ ${DOWNLOAD_STATUS} == 0 ]];then
    printf "Developer disk image download status: \x1B[32mDOWNLOADED\x1B[0m \xE2\x9C\x94 \n"
    echo "Unzipping: ${DEVICE_OS_VERSION}"
    unzip ${DEVICE_OS_VERSION}.zip
    sleep 0.1
    echo "Moving: $DEVICE_OS_VERSION to: Disk_Images/${DEVICE_TYPE}/${DEVICE_OS_VERSION}"
    mv ${DEVICE_OS_VERSION} "Disk_Images/${DEVICE_TYPE}"
    sleep 0.1
    printf "Removing ZIP file. \n\n"
    rm -rf ${DEVICE_OS_VERSION}.zip*
    sleep 1
    elif [[ ${DOWNLOAD_STATUS} == 1 ]];then
    printf "Developer disk image download status: \x1B[32mALREADY DOWNLOADED\x1B[0m \xE2\x9C\x94 \n"
    sleep 0.1
    else
    printf "\x1B[31mComputer is not connected to the internet!\x1B[0m \xE2\x9D\x8C \n\n"
    read -p "Press [Enter]: "
    menu
    fi


    MOUNT_STATUS=$(ideviceimagemounter -l | grep ImageSignature | awk '{print $1}')
    if [[ $MOUNT_STATUS == "ImageSignature[0]:" ]];then
    printf "Developer disk image mount status: \x1B[31mNOT MOUNTED!\x1B[0m \xE2\x9D\x8C \n"
    echo "Using: $DEVICE_TYPE $DEVICE_OS_VERSION disk image."
    cd Disk_Images/${DEVICE_TYPE}/${DEVICE_OS_VERSION}
    printf "Mounting... \n\n"
    sleep 0.1
    LOCK_STATUS=$(ideviceimagemounter -u ${DEVICE_UDID} DeveloperDiskImage.dmg DeveloperDiskImage.dmg.signature | grep "ERROR:")
    cd ../../..
    sleep 1
    fi


    if [[ $LOCK_STATUS == "ERROR: Device is locked, can't mount. Unlock device and try again." ]];then
    printf "\nDevice locked! Please unlock the device to mount it. \xE2\x9D\x8C \n\n"
    read -p "Press [Enter]: "
    menu
    fi
    printf "Develeper disk image mount status: \x1B[32mMOUNTED\x1B[0m \xE2\x9C\x94 \n\n"
    sleep 0.1
    }


    ####################
    #SET DEVICE LOCATION
    ####################
    function setDeviceLocation() {
    checkDeviceConnection
    read -p "Enter [street, city, province/state, and country] or [B/b] to go back: " STREET_CITY_PROVINCE_COUNTRY


    if [[ $STREET_CITY_PROVINCE_COUNTRY =~ ^(B|b)$ ]];then
    menu
    fi


    XML=$(curl -s -X POST -d locate="${STREET_CITY_PROVINCE_COUNTRY}" \
    -d geoit="xml" \
    -d auth=${API_KEY} \
    https://geocode.xyz)


    INTERNET_ON=${XML}
    if ! [[ ${INTERNET_ON} ]];then
    printf "\n\x1B[31mNO INTERNET CONNECTION!\x1B[0m \xE2\x9D\x8C\n"
    printf "Please connect to the internet and try again.\n\n"
    read -p "Press [Enter]: "
    setDeviceLocation
    fi


    if ! [[ ${API_KEY} ]];then
    printf "\n\x1B[31mNO API KEY!\x1B[0m \xE2\x9D\x8C\n"
    printf "1.) Sign up for a free API key at https://geocode.xyz \n"
    printf "2.) Go to the Account Home page \n\n"
    read -p "Enter your API key: " API_KEY
    echo ${API_KEY} > "API_Key/API_Key.txt"
    printf "\n"
    read -p "Press [Enter]: "
    setDeviceLocation
    fi


INVALID_API_KEY=$(echo ${XML} | grep "not found")
if [[ ${INVALID_API_KEY} ]];then
printf "\n\x1B[31mINVALID API KEY!\x1B[0m \xE2\x9D\x8C\n"
printf "1.) Sign up for a free API key at https://geocode.xyz \n"
printf "2.) Go to the Account Home page \n\n"
read -p "Enter your API key: " API_KEY
echo ${API_KEY} > "API_Key/API_Key.txt"
printf "\n"
read -p "Press [Enter]: "
setDeviceLocation
fi


ADD_CREDITS=$(echo ${XML} | grep -o '<description>.*</description>' | sed -e 's/<[^>]*>//g' | grep "has ran out of credits." | awk '{printf $1}')
LAT=$(echo ${XML} | grep -o '<latt>.*</latt>' | sed -e 's/<[^>]*>//g' | awk 'length >= 7')
LONG=$(echo ${XML} | grep -o '<longt>.*</longt>' | sed -e 's/<[^>]*>//g' | awk 'length >= 7')
if [[ ${LAT} && ${LONG} ]];then
STREET=$(echo ${XML} | grep -o '<addresst>.*</addresst>' | sed -e 's/<[^>]*>//g')
CITY=$(echo ${XML} | grep -o '<city>.*</city>' | sed -e 's/<[^>]*>//g')
PROVINCE=$(echo ${XML} | grep -o '<statename>.*</statename>' | sed -e 's/<[^>]*>//g')
COUNTRY=$(echo ${XML} | grep -o '<countryname>.*</countryname>' | sed -e 's/<[^>]*>//g')
DEVICE_LOCATION=$(echo ${STREET} ${CITY} ${PROVINCE} ${COUNTRY})
POSTAL=$(echo ${XML} | grep -o '<postal>.*</postal>' | sed -e 's/<[^>]*>//g')
elif [[ ${ADD_CREDITS} ]];then
printf "\n\x1B[31mNO CREDITS!!\x1B[0m \xE2\x9D\x8C\n"
printf "Add credits to your geocode.xyz account, with API key ${ADD_CREDITS}. \n\n"
read -p "Press [Enter]: "
menu
else
printf "\n\x1B[31mINVALID!\x1B[0m \xE2\x9D\x8C\n"
printf "Please enter, at least the city, province/state, and country.\n\n"
read -p "Press [Enter]: "
setDeviceLocation
fi
}


function ctrl_c() {
clear
printf "\033[0;33mUNPAIRING...\x1B[0m \n"
idevicepair unpair
printf "\x1B[31mEXITING!\x1B[0m \n\n"
exit
}
