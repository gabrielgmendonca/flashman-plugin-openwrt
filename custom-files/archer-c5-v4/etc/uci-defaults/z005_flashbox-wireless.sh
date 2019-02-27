#!/bin/sh

#
# WARNING! This file might be a symbolic link! Check your sources!
#

. /usr/share/flashman_init.conf
. /usr/share/functions/device_functions.sh
. /lib/functions/system.sh

MAC_LAST_CHARS=$(get_mac | awk -F: '{ print $5$6 }')
SSID_VALUE=$(uci -q get wireless.@wifi-iface[0].ssid)
ENCRYPTION_VALUE=$(uci -q get wireless.@wifi-iface[0].encryption)
LOWERMAC=$(get_mac | awk '{ print tolower($1) }')
LOWERMAC_5=$(macaddr_add "$LOWERMAC" 2)
SUFFIX_5="-5GHz"

# Wireless password cannot be empty or have less than 8 chars
if [ "$FLM_PASSWD" == "" ] || [ $(echo "$FLM_PASSWD" | wc -m) -lt 9 ]
then
  FLM_PASSWD=$(get_mac | sed -e "s/://g")
fi

# Configure WiFi default SSID and password
if { [ "$SSID_VALUE" = "OpenWrt" ] || [ "$SSID_VALUE" = "LEDE" ] || \
     [ "$SSID_VALUE" = "" ]; } && [ "$ENCRYPTION_VALUE" != "psk2" ]
then
  if [ "$FLM_SSID_SUFFIX" == "none" ]
  then
    #none
    setssid="$FLM_SSID"
  else
    #lastmac
    setssid="$FLM_SSID$MAC_LAST_CHARS"
  fi
  touch /etc/config/wireless

  uci set wireless.radio0=wifi-device
  # Disable the interface!
  # MT7620 use a dat file, we only get the parameters from here
  uci set wireless.@wifi-device[0].type="ralink"
  uci set wireless.@wifi-device[0].txpower="100"
  uci set wireless.@wifi-device[0].variant="mt7620"
  # Current MT7620 driver has a bug with 2.4 "auto" channel mode
  if [ "$FLM_24_CHANNEL" = "auto" ]
  then
    uci set wireless.@wifi-device[0].channel="6"
  else
    uci set wireless.@wifi-device[0].channel="$FLM_24_CHANNEL"
  fi
  uci set wireless.@wifi-device[0].hwmode="11n"
  uci set wireless.@wifi-device[0].wifimode="9"
  uci set wireless.@wifi-device[0].country="BR"
  uci set wireless.@wifi-device[0].htmode="HT40"
  uci set wireless.@wifi-device[0].noscan="1"
  uci set wireless.@wifi-device[0].ht_bsscoexist="0"
  uci set wireless.@wifi-device[0].bw="1"
  uci set wireless.@wifi-device[0].disabled="1"
  uci set wireless.default_radio0=wifi-iface
  uci set wireless.@wifi-iface[0].ifname="ra0"
  uci set wireless.@wifi-iface[0].mode="ap"
  uci set wireless.@wifi-iface[0].network="lan"
  uci set wireless.@wifi-iface[0].device="radio0"
  uci set wireless.@wifi-iface[0].ssid="$setssid"
  uci set wireless.@wifi-iface[0].encryption="psk2"
  uci set wireless.@wifi-iface[0].key="$FLM_PASSWD"
  # 5GHz - MT7612e
  uci set wireless.radio1=wifi-device
  # Disable the interface!
  # MT7612e use a dat file, we only get the parameters from here
  uci set wireless.@wifi-device[1].type="ralink"
  uci set wireless.@wifi-device[1].txpower="100"
  uci set wireless.@wifi-device[1].variant="mt7612e"
  uci set wireless.@wifi-device[1].channel="$FLM_50_CHANNEL"
  uci set wireless.@wifi-device[1].hwmode="11ac"
  uci set wireless.@wifi-device[1].wifimode="15"
  uci set wireless.@wifi-device[1].country="BR"
  uci set wireless.@wifi-device[1].htmode="VHT80"
  uci set wireless.@wifi-device[1].noscan="1"
  uci set wireless.@wifi-device[1].ht_bsscoexist="0"
  uci set wireless.@wifi-device[1].bw="2"
  uci set wireless.@wifi-device[1].disabled="1"
  uci set wireless.default_radio1=wifi-iface
  uci set wireless.@wifi-iface[1].ifname="rai0"
  uci set wireless.@wifi-iface[1].mode="ap"
  uci set wireless.@wifi-iface[1].network="lan"
  uci set wireless.@wifi-iface[1].device="radio1"
  uci set wireless.@wifi-iface[1].ssid="$setssid$SUFFIX_5"
  uci set wireless.@wifi-iface[1].encryption="psk2"
  uci set wireless.@wifi-iface[1].key="$FLM_PASSWD"

  uci commit wireless
fi

/usr/bin/uci2dat -d radio0 -f /etc/Wireless/RT2860/RT2860AP.dat > /dev/null
printf "MacAddress=$LOWERMAC\n\n" >> /etc/Wireless/RT2860/RT2860AP.dat
insmod /lib/modules/`uname -r`/mt7620.ko mac=$LOWERMAC
echo "mt7620 mac=$LOWERMAC" >> /etc/modules.d/50-mt7620

#Dump firmware in /lib/firmware for mt7612e
dd if=/dev/mtd8ro of=/lib/firmware/mt7612e.eeprom.bin bs=1k skip=32 count=32

# 5 GHz
/usr/bin/uci2dat -d radio1 -f /etc/Wireless/mt76x2e/mt76x2e.dat > /dev/null
printf "MacAddress=$LOWERMAC_5\n\n" >> /etc/Wireless/mt76x2e/mt76x2e.dat
insmod /lib/modules/`uname -r`/mt76x2e.ko mac=$LOWERMAC_5
echo "mt76x2e mac=$LOWERMAC_5" >> /etc/modules.d/51-mt7612e

[ -e /sbin/wifi ] && mv /sbin/wifi /sbin/wifi_legacy
cp /sbin/mtkwifi /sbin/wifi
# MT7620 driver needs to reload the first time it loads
/sbin/wifi reload

exit 0
