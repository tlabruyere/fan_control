#!/bin/bash
#####################################
#####################################
#
#
# crontab -l > mycron
# echo "#" >> mycron
# echo "# At every 2nd minute" >> mycron
# echo "*/2 * * * * /bin/bash /scripts/dell_ipmi_fan_control.sh >> /tmp/cron.log" >> mycron
# crontab mycron
# rm mycron
# chmod +x /scripts/dell_ipmi_fan_control.sh
#
#####################################
# Reddit: https://www.reddit.com/r/homelab/comments/7xqb11/dell_fan_noise_control_silence_your_poweredge/?utm_medium=android_app&utm_source=share
# 
# # print temps and fans rpms
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> sensor reading "Ambient Temp" "FAN 1 RPM" "FAN 2 RPM" "FAN 3 RPM"
# 
# # print fan info
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> sdr get "FAN 1 RPM" "FAN 2 RPM" "FAN 3 RPM"
# 
##  enable manual/static fan control
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> raw 0x30 0x30 0x01 0x00
# 
##  disable manual/static fan control
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> raw 0x30 0x30 0x01 0x01
# 
## set fan speed to 0 rpm
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> raw 0x30 0x30 0x02 0xff 0x00
# 
## set fan speed to 20 %
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> raw 0x30 0x30 0x02 0xff 0x14
# 
## set fan speed to 30 %
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> raw 0x30 0x30 0x02 0xff 0x1e
# 
## set fan speed to 100 %
# ipmitool -I lanplus -H <iDRAC-IP> -U <iDRAC-USER> -P <iDRAC-PASSWORD> raw 0x30 0x30 0x02 0xff 0x64
#####################################
#####################################

DATE=$(date +%Y-%m-%d-%H%M%S)
echo "" && echo "" && echo "" && echo "" && echo ""
echo "$DATE"
#
#IDRACIP="<iDRAC-IP>"
#IDRACUSER="<iDRAC-USER>"
#IDRACPASSWORD="<iDRAC-PASSWORD>"
STATICSPEEDBASE16="0x0f"
# 0x00 = 0% of max speed
# 0x0f = 15% of max speed
# 0x1e = 30% of max speed
# 0x64 = 100% of max speed
#SENSORNAME="Ambient"
CPU_T1_NAME="0Eh"
CPU_T2_NAME="0Fh"
TEMPTHRESHOLD="65"

#ipmitool -I lanplus -H ${IDRAC_HOST} -U ${IDRAC_USER} -P ${IDRAC_PASS} sdr type temperature | grep ${CPU_T1_NAME} | cut -d"|" -f5 | cut -d" " -f2

# TODO: MAKE THIS 1 CALL
CPU_T1=$(ipmitool -I lanplus -H $IDRAC_HOST -U $IDRAC_USER -P $IDRAC_PASS sdr type temperature | grep $CPU_T1_NAME | cut -d"|" -f5 | cut -d" " -f2)
CPU_T2=$(ipmitool -I lanplus -H $IDRAC_HOST -U $IDRAC_USER -P $IDRAC_PASS sdr type temperature | grep $CPU_T2_NAME | cut -d"|" -f5 | cut -d" " -f2)
##### T=$(ipmitool -I lanplus -H $IDRACIP2 -U $IDRACUSER -P $IDRACPASSWORD sdr type temperature | grep $SENSORNAME2 | cut -d"|" -f5 | cut -d" " -f2 | grep -v "Disabled")
echo "IDRAC: $IDRAC_HOST: -- current temperature --"
echo "CPU_TEMP 1: $CPU_T1 C"
echo "CPU_TEMP 2: $CPU_T2 C"
MAX_TEMP=$(($CPU_T1 > $CPU_T2 ? $CPU_T1 : $CPU_T2))
echo "MAX_TEMP: $MAX_TEMP C" 
if [[ $MAX_TEMP > $TEMPTHRESHOLD ]]
  then
    # SET DYNAMIC FAN CONTROL - 
    echo "--> enable dynamic fan control"
    ipmitool -I lanplus -H $IDRAC_HOST -U $IDRAC_USER -P $IDRAC_PASS raw 0x30 0x30 0x01 0x01
  else
    echo "--> disable dynamic fan control"
    # SET MANUAL FAN CONTROL
    ipmitool -I lanplus -H $IDRAC_HOST -U $IDRAC_USER -P $IDRAC_PASS raw 0x30 0x30 0x01 0x00
    echo "--> set static fan speed"
    # SET FAN SPEED TO to stacic speed
    ipmitool -I lanplus -H $IDRAC_HOST -U $IDRAC_USER -P $IDRAC_PASS raw 0x30 0x30 0x02 0xff $STATICSPEEDBASE16
fi

