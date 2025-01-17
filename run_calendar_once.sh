#!/bin/bash
date >> /home/kim/eink.log
echo "start" >> /home/kim/eink.log

sleep 60

battery=$(echo "get battery" | nc -q 0 127.0.0.1 8423)
echo "battery: ${battery}" >> /home/kim/eink.log
if [[ x"$battery" =~ "battery:" ]]; then
  battery=${battery#*" "}
  battery=${battery%.*}
  echo -n $battery > /home/kim/battery
fi

cd $(dirname $0)
git pull
python3 ./run_calendar_once.py

set -e

# Wakeup after n seconds
WAKEUP_AFTER=7200

rtc_time=$(echo "get rtc_time" | nc -q 0 127.0.0.1 8423)
echo "rtc_time: ${rtc_time}" >> /home/kim/eink.log
if [[ x"$rtc_time" =~ "rtc_time:" ]]; then
    rtc_time=${rtc_time#*" "}

    # Next wakeup time
    wakeup_time=$(date -d $rtc_time +%s)
    wakeup_time=$(($wakeup_time + $WAKEUP_AFTER));
    wakeup_time=$(date -d @$wakeup_time --iso-8601=seconds)

    r=$(echo "rtc_alarm_set ${wakeup_time} 127" | nc -q 0 127.0.0.1 8423)
    if [[ x"$r" =~ "done" ]]; then
        sleep 30
        sudo shutdown now
    else
        echo "Set RTC wakeup time error" >> /home/kim/eink.log
        sudo reboot
    fi
else
    echo "Get RTC time errror" >> /home/kim/eink.log
    sudo reboot
fi
