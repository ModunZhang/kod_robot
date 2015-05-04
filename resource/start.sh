#!/bin/bash

echo > log

function runClient()
{
	./kod_client $1
	# >> log
}


if [ ${#@} -eq 1 ]; then
	runClient $@
elif [ ${#@} -eq 2 ]; then 
	for(( i = $1; i <= $2; i++ ))
	do
	{
		runClient $i
	}&
	done
fi
wait