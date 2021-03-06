#!/bin/sh

get_custom_leds_blink() {
	echo "$(ls -d /sys/class/leds/*orange*)"
}

#Force a memory cleanup to avoid processor usage in network
anlix_force_clean_memory() {
	echo 3 > /proc/sys/vm/drop_caches
}

anlix_upgrade_clean_memory() {
	wifi down
	sleep 3
	rmmod ath9k
	rmmod ath9k_common
	rmmod ath9k_hw
	rmmod mac80211
	echo 3 > /proc/sys/vm/drop_caches
}

anlix_upgrade_restore_memory() {
	modprobe mac80211
	modprobe ath9k_hw
	modprobe ath9k_common
	modprobe ath9k
	wifi up
}
