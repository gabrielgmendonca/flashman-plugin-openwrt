#!/bin/sh
# WARNING! This file may be replaced depending on the selected target!

. /usr/share/libubox/jshn.sh
. /usr/share/flashman_init.conf
. /usr/share/functions/device_functions.sh
. /usr/share/functions/wireless_functions.sh

MAC_LAST_CHARS=$(get_mac | awk -F: '{ print $5$6 }')
SSID_VALUE=$(uci -q get wireless.@wifi-iface[0].ssid)
SUFFIX_5="-5GHz"

json_cleanup
json_load_file /root/flashbox_config.json
json_get_var _mesh_mode mesh_mode
json_get_var _mesh_master mesh_master
json_get_var _ssid_24 ssid_24
json_get_var _password_24 password_24
json_get_var _channel_24 channel_24
json_get_var _htmode_24 htmode_24
json_get_var _state_24 state_24
if [ "$(is_5ghz_capable)" == "1" ]
then
	json_get_var _ssid_50 ssid_50
	json_get_var _password_50 password_50
	json_get_var _channel_50 channel_50
	json_get_var _htmode_50 htmode_50
	json_get_var _state_50 state_50
fi
json_close_object

if [ -z "$_ssid24" ]
then
	#use defaults
	[ "$FLM_SSID_SUFFIX" == "none" ] && setssid="$FLM_SSID" || setssid="$FLM_SSID$MAC_LAST_CHARS"
	# Wireless password cannot be empty or have less than 8 chars
	if [ "$FLM_PASSWD" == "" ] || [ $(echo "$FLM_PASSWD" | wc -m) -lt 9 ]
	then
		FLM_PASSWD=$(get_mac | sed -e "s/://g")
	fi

	_ssid_24=$setssid
	_password_24="$FLM_PASSWD"
	_channel_24="$FLM_24_CHANNEL"
	_htmode_24="$([ "$FLM_24_BAND" = "HT40" ] && echo "HT40" || echo "HT20")"
	_state_24="1"

	_ssid_50="$setssid$SUFFIX_5"
	_password_50="$FLM_PASSWD"
	_channel_50="$FLM_50_CHANNEL"
	_htmode_50="$([ "$(is_5ghz_vht)" ] && echo "VHT80" || echo "HT40")"
	_state_50="1"
fi

if [ "$SSID_VALUE" != "OpenWrt" ] && [ "$SSID_VALUE" != "LEDE" ] && [ -n "$SSID_VALUE" ]
then
	# reset /etc/config/wireless
	rm /etc/config/wireless
	wifi config
fi

local _phy0=$(get_radio_phy "0")
if [ "$(get_phy_type $_phy0)" -eq "2" ]
then
	# 2.4 Radio is always first radio
	uci rename wireless.radio0=radiotmp
	uci rename wireless.radio1=radio0
	uci rename wireless.radiotmp=radio1
	uci rename wireless.default_radio0=default_radiotmp
	uci rename wireless.default_radio1=default_radio0
	uci rename wireless.default_radiotmp=default_radio1
	uci set wireless.default_radio0.device='radio0'
	uci set wireless.default_radio1.device='radio1'
	uci reorder wireless.radio0=0
	uci reorder wireless.default_radio0=1
	uci reorder wireless.radio1=2
	uci reorder wireless.default_radio1=3
fi

uci set wireless.@wifi-device[0].txpower="17"
uci set wireless.@wifi-device[0].htmode="$_htmode_24"
uci set wireless.@wifi-device[0].noscan="0"
[ "$_htmode_24" = "HT40" ] && uci set wireless.@wifi-device[0].noscan="1"
uci set wireless.@wifi-device[0].country="BR"
uci set wireless.@wifi-device[0].channel="$_channel_24"
uci set wireless.@wifi-device[0].channels="1-11"
uci set wireless.@wifi-device[0].disabled="$([ "$_state_24" = "1" ] && echo "0" || echo "1")"
uci set wireless.@wifi-iface[0].ifname='wlan0'
uci set wireless.@wifi-iface[0].ssid="$_ssid_24"
uci set wireless.@wifi-iface[0].encryption="psk2"
uci set wireless.@wifi-iface[0].key="$_password_24"

if [ "$(is_5ghz_capable)" == "1" ]
then
	uci set wireless.@wifi-device[1].txpower="17"
	uci set wireless.@wifi-device[1].channel="$_channel_50"
	uci set wireless.@wifi-device[1].country="BR"
	uci set wireless.@wifi-device[1].htmode="$_htmode_50"
	uci set wireless.@wifi-device[1].noscan="1"
	uci set wireless.@wifi-device[1].disabled="$([ "$_state_50" = "1" ] && echo "0" || echo "1")"
	uci set wireless.@wifi-iface[1].ifname='wlan1'
	uci set wireless.@wifi-iface[1].ssid="$_ssid_50"
	uci set wireless.@wifi-iface[1].encryption="psk2"
	uci set wireless.@wifi-iface[1].key="$_password_50"
fi

if [ "$_mesh_mode" -gt "0" ]
then
	if [ -z "$_mesh_master" ]
	then
		set_mesh_master_mode "$_mesh_mode"
	else
		set_mesh_slave_mode "$_mesh_mode" "$_mesh_master"
	fi
	enable_mesh_routing "$_mesh_mode"
fi

uci commit wireless

exit 0
