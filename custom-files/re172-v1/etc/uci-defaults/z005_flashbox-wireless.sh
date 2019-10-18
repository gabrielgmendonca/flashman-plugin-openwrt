#!/bin/sh

#
# WARNING! This file may be replaced depending on the selected target!
#

. /usr/share/flashman_init.conf
. /usr/share/functions/device_functions.sh

LOWERMAC=$(get_mac | awk '{ print tolower($1) }')
MAC_WIFI=$(macaddr_add "$LOWERMAC" -1)
MAC_LAST_CHARS=$(get_mac | awk -F: '{ print $5$6 }')
SSID_VALUE=$(uci -q get wireless.@wifi-iface[0].ssid)
ENCRYPTION_VALUE=$(uci -q get wireless.@wifi-iface[0].encryption)

# Wireless password cannot be empty or have less than 8 chars
if [ "$FLM_PASSWD" == "" ] || [ $(echo "$FLM_PASSWD" | wc -m) -lt 9 ]
then
  FLM_PASSWD=$(get_mac | sed -e "s/://g")
fi

# Configure WiFi default SSID and password
if { [ "$SSID_VALUE" = "OpenWrt" ] || [ "$SSID_VALUE" = "LEDE" ] || \
     [ "$SSID_VALUE" = "" ]; } && [ "$ENCRYPTION_VALUE" != "psk2+tkip+ccmp" ]
then
  if [ "$FLM_SSID_SUFFIX" == "none" ]
  then
    #none
    setssid="$FLM_SSID"
  else
    #lastmac
    setssid="$FLM_SSID$MAC_LAST_CHARS"
  fi

  uci set wireless.@wifi-device[0].type="mac80211"
  uci set wireless.@wifi-device[0].txpower="17"
  uci set wireless.@wifi-device[0].channel="$FLM_24_CHANNEL"
  uci set wireless.@wifi-device[0].hwmode="11n"
  uci set wireless.@wifi-device[0].country="BR"

  if [ "$FLM_24_BAND" = "HT40" ]
  then
    uci set wireless.@wifi-device[0].htmode="$FLM_24_BAND"
    uci set wireless.@wifi-device[0].noscan="1"
  elif [ "$_remote_htmode_24" = "HT20" ]
  then
    uci set wireless.@wifi-device[0].htmode="$FLM_24_BAND"
    uci set wireless.@wifi-device[0].noscan="0"
  else
    uci set wireless.@wifi-device[0].htmode="HT20"
    uci set wireless.@wifi-device[0].noscan="0"
  fi

  uci set wireless.@wifi-device[0].disabled="0"
  uci set wireless.@wifi-iface[0].ssid="$setssid"
  uci set wireless.@wifi-iface[0].encryption="psk2+tkip+ccmp"
  uci set wireless.@wifi-iface[0].key="$FLM_PASSWD"
  uci set wireless.@wifi-iface[0].macaddr="$MAC_WIFI"

  uci commit wireless
fi

exit 0