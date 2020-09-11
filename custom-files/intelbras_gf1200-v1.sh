#!/bin/sh

anlix_bootup_defaults() {
	ifconfig wlan0 up
	iwpriv wlan0 set_mib xcap=31
	iwpriv wlan0 set_mib ther=43
	iwpriv wlan0 set_mib pwrlevelCCK_A=2d2d2d2e2e2e2e2e2e3030303030
	iwpriv wlan0 set_mib pwrlevelCCK_B=2a2a2a2c2c2c2c2c2c2e2e2e2e2e
	iwpriv wlan0 set_mib pwrlevelHT40_1S_A=2828282828282828282a2a2a2a2a
	iwpriv wlan0 set_mib pwrlevelHT40_1S_B=2626262727272727272828282828
	iwpriv wlan0 set_mib pwrdiffHT20=1111111111111111111111111111
	iwpriv wlan0 set_mib pwrdiffOFDM=2222222222222222222222222222
	ifconfig wlan0 down

	ifconfig wlan1 up
	iwpriv wlan1 set_mib xcap=59
	iwpriv wlan1 set_mib ther=28
	iwpriv wlan1 set_mib pwrlevel5GHT40_1S_A=00000000000000000000000000000000000000000000000000000000000000000000002323232323232322222222222222222222222222222222222222222222242424242424242424242424242424242424242424242424242424242424242424242424242424242424262626262626272727272727272727272222222222222121212121212121212121212121212127272727272727272727272a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a00000000000000000000000000000000000000
	iwpriv wlan1 set_mib pwrlevel5GHT40_1S_B=00000000000000000000000000000000000000000000000000000000000000000000002222222222222223232323232321212121212121212121202020202020232323232323232323232323232323232323232323232323232323232323232323232323232323232323252525252525272727272727272727272121212121211f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f25252525252525252525252929292929292929292929292929292929292929292900000000000000000000000000000000000000
	ifconfig wlan1 down
}

get_custom_mac() {
	. /lib/functions/system.sh
	local _mac_address_tag=""
	local _p1

	_p1=$(mtd_get_mac_binary boot 131079 | awk '{print toupper($1)}')
	[ ! -z "$_p1" ] && _mac_address_tag=$_p1

	echo "$_mac_address_tag"
}

set_switch_bridge_mode_on_boot() {
	local _disable_lan_ports="$1"

	if [ "$_disable_lan_ports" = "y" ]
	then
		# eth0
		swconfig dev switch0 vlan 9 set ports ''
		# eth1
		swconfig dev switch0 vlan 8 set ports '0 6'
		else
		# eth0
		swconfig dev switch0 vlan 9 set ports ''
		# eth1
		swconfig dev switch0 vlan 8 set ports '1 2 3 6'
	fi
}

custom_wan_port() {
	[ $1 == 1 ] && echo "switch0" || echo "0"
}

get_custom_leds_blink() {
	echo "$(ls -d /sys/class/leds/*blue*)"
}
