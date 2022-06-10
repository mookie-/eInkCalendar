#!/bin/bash
battery=$(echo "get battery" | nc -q 0 127.0.0.1 8423)
if [[ x"$rtc_time" =~ "battery:" ]]; then
  battery=${battery#*" "}
  battery=${battery%.*}
  echo -n $battery > /home/kim/battery
fi

cd $(dirname $0)
python3 ./run_calendar_once.py

set -e

# Wakeup after n seconds
WAKEUP_AFTER=1800

rtc_time=$(echo "get rtc_time" | nc -q 0 127.0.0.1 8423)
if [[ x"$rtc_time" =~ "rtc_time:" ]]; then
    rtc_time=${rtc_time#*" "}

    # Next wakeup time
    wakeup_time=$(date -d $rtc_time +%s)
    wakeup_time=$(($wakeup_time + $WAKEUP_AFTER));
    wakeup_time=$(date -d @$wakeup_time --iso-8601=seconds)

    r=$(echo "rtc_alarm_set ${wakeup_time} 127" | nc -q 0 127.0.0.1 8423)
    if [[ x"$r" =~ "done" ]]; then
        sudo shutdown now
    else
        echo "Set RTC wakeup time error"
        exit 1
    fi
else
    echo "Get RTC time errror"
    exit 1
fi
