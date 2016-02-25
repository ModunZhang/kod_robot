#!/bin/bash

echo > log

function runClient()
{
	./kod_client $1 > /dev/null 2>&1
	# >> log
}


if [ ${#@} -eq 1 ]; then
	runClient $@
elif [ ${#@} -eq 2 ]; then 
	for(( i = $1; i <= $2; i++ ))
	do
	{
		sleep 5
		runClient $i
	}&
	done
fi
wait