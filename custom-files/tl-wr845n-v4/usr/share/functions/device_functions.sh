#!/bin/sh

save_wifi_local_config() {
  uci commit wireless
  /usr/bin/uci2dat -d radio0 -f /etc/wireless/mt7628/mt7628.dat > /dev/null
}

led_off() {
  if [ -f "$1"/trigger ]
  then
    echo "none" > "$1"/trigger
    echo "0" > "$1"/brightness
  fi
}

led_netdev() {
  echo "netdev" > "$1"/trigger
  echo "link tx rx" > "$1"/mode
  echo "$2" > "$1"/device_name
}

reset_leds() {
  for trigger_path in $(ls -d /sys/class/leds/*)
  do
    led_off "$trigger_path"
  done
  /etc/init.d/led restart > /dev/null
  led_netdev /sys/class/leds/$(cat /tmp/sysinfo/board_name)\:green\:wan eth0.2
}

blink_leds() {
  local _do_restart=$1
  local _bname=$(cat /tmp/sysinfo/board_name)
  if [ $_do_restart -eq 0 ]
  then
    led_off /sys/class/leds/$(cat /tmp/sysinfo/board_name)\:green\:wan
    echo "timer" > /sys/class/leds/$_bname\:green\:wlan/trigger
    echo "timer" > /sys/class/leds/$_bname\:orange\:wan/trigger
  fi
}

get_mac() {
  local _mac_address_tag=""

  if [ ! -z "$(awk '{ print toupper($1) }' /sys/class/net/eth0/address)" ]
  then
    _mac_address_tag=$(awk '{ print toupper($1) }' /sys/class/net/eth0/address)
  fi

  echo "$_mac_address_tag"
}
