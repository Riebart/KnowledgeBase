#!/bin/bash

# Use telnet and a loop to change the tick rate of a server (adjusting the time per day) based on the number of players.

lastlp=1

function telnet_write {
  echo "$1"
  sleep 0.75
  echo "exit"
}

telnet_write "ggs" | nc -w1 localhost 8081 | grep "GameStat.TimeOfDayIncPerSec"
telnet_write "lp" | nc -w1 localhost 8081 | grep "Total of"

while [ true ]
do
  lp=$(telnet_write "lp" | nc -w1 localhost 8081 | sed -n 's/Total of \([0-9]*\) in the game/\1/p' | tr -dc '0-9')

  if [ "$lp" != "$lastlp" ]
  then
    if [ $lp -lt 2 ]
    then
      tickrate=1
    elif [ $lp -lt 4 ]
    then
      tickrate=$lp
    else
      tickrate=$[lp+1]
    fi

    echo "Player count changed from $lastlp to $lp"
    echo "Current game tick rate: $(telnet_write 'ggs' | nc -w1 localhost 8081 | grep GameStat.TimeOfDayIncPerSec)"
    echo "New game tick rate: $tickrate"
    telnet_write "sgs TimeOfDayIncPerSec $tickrate" | tee /dev/stderr | nc -w1 localhost 8081 > /dev/null 2>&1
    echo "New effective game tick rate: $(telnet_write 'ggs' | nc -w1 localhost 8081 | grep GameStat.TimeOfDayIncPerSec)"
  else
    echo "No change in player count on the server"
  fi

  lastlp="$lp"

  sleep 10
done | while read line
do
  echo "`date | tr -d '\n'` $line"
done
