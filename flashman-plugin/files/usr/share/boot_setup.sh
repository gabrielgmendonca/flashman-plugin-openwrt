#!/bin/sh

. /usr/share/flashman_init.conf
. /lib/functions.sh
. /usr/share/functions.sh

HARDWARE_MODEL=$(cat /proc/cpuinfo | sed -n 2p | awk '{ print $4 }' | sed 's/\//-/g')
CLIENT_MAC=$(get_mac)

log() {
	logger -t "FlashMan Plugin Boot " "$@"
}

firstboot() {
	uci set system.@system[-1].hostname="$HARDWARE_MODEL-$FLM_RELID"
	uci set system.@system[-1].cronloglevel="9"
	uci commit system

	uci set system.ntp.enabled="0"
	uci set system.ntp.enable_server="0"
	uci commit system
	/etc/init.d/system restart

	# Set firewall rules
	uci set firewall.@defaults[-1].input="ACCEPT"
	uci set firewall.@defaults[-1].output="ACCEPT"
	uci set firewall.@defaults[-1].forward="REJECT"
	uci commit firewall

	# Lan
	uci set firewall.@zone[0].input="ACCEPT"
	uci set firewall.@zone[0].output="ACCEPT"
	uci set firewall.@zone[0].forward="REJECT"
	uci commit firewall

	# Wan
	uci set firewall.@zone[1].input="ACCEPT"
	uci set firewall.@zone[1].output="ACCEPT"
	uci set firewall.@zone[1].forward="REJECT"
	uci set firewall.@zone[1].network="wan"
	uci commit firewall

	# SSH access
	uci add firewall rule
	uci set firewall.@rule[-1].enabled="1"
	uci set firewall.@rule[-1].target="ACCEPT"
	uci set firewall.@rule[-1].proto="tcp"
	uci set firewall.@rule[-1].dest_port="36022"
	uci set firewall.@rule[-1].name="custom-ssh"
	uci set firewall.@rule[-1].src="*"
	uci commit firewall

	uci set dropbear.@dropbear[0]=dropbear
	uci set dropbear.@dropbear[0].PasswordAuth=on
	uci set dropbear.@dropbear[0].RootPasswordAuth=on
	uci set dropbear.@dropbear[0].Port=36022
	uci commit dropbear
	/etc/init.d/dropbear restart

	# Configure WiFi default SSID and password
	ssid_value=$(uci get wireless.@wifi-iface[0].ssid)
	encryption_value=$(uci get wireless.@wifi-iface[0].encryption)
	if [ "$ssid_value" = "OpenWrt" ] && [ "$encryption_value" = "none" ]
	then
		uci set wireless.@wifi-device[0].disabled="0"
		uci set wireless.@wifi-device[0].type="mac80211"
		uci set wireless.@wifi-device[0].channel="11"
		uci commit wireless
		uci set wireless.@wifi-iface[0].disabled="0"
		uci set wireless.@wifi-iface[0].ssid="$FLM_SSID"
		uci set wireless.@wifi-iface[0].encryption="psk2"
		uci set wireless.@wifi-iface[0].key="$FLM_PASSWD"
		uci commit wireless
		uci set wireless.@wifi-device[1].disabled="0"
		uci set wireless.@wifi-device[1].type="mac80211"
		uci set wireless.@wifi-device[1].channel="36"
		uci commit wireless
		uci set wireless.@wifi-iface[1].disabled="0"
		uci set wireless.@wifi-iface[1].ssid="$FLM_SSID"
		uci set wireless.@wifi-iface[1].encryption="psk2"
		uci set wireless.@wifi-iface[1].key="$FLM_PASSWD"
		uci commit wireless
	fi
	/sbin/wifi up

	# Configure LAN
	uci set network.lan.ipaddr="10.0.10.1"
	uci set network.lan.netmask="255.255.255.0"
	uci commit network
	/sbin/ifup lan

	# Set root password
	PASSWORD_ENTRY=""
	(
		echo "$CLIENT_MAC" | awk -F ":" '{ print $1$2$3$4$5$6 }'
		sleep 1
		echo "$CLIENT_MAC" | awk -F ":" '{ print $1$2$3$4$5$6 }'
	)|passwd root

	# Set GMT-3
	echo BRT3BRST,M10.3.0/0,M2.3.0/0 > /etc/TZ
	# Sync date and time with GMT-3
	ntpd -n -q -p a.st1.ntp.br -p b.st1.ntp.br -p c.st1.ntp.br -p d.st1.ntp.br

	log "First boot completed"
}

log "Starting..."

[ -f "/etc/firstboot" ] || {
	firstboot
}

log "Done!"

echo "0" > /etc/firstboot
