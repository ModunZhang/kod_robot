#!/bin/bash
function start()
{
	echo start $1,$2
	sh start.sh $1 $2 > /dev/null 2>&1 &
}

executetime=60
s=0
e=0
function getNext()
{
	inner=$1
	let "s = (inner-1)*10+1"
	let "e = inner * 10"
}

function run()
{
	index=$1
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
	sleep $executetime
	let "index+=1"
	getNext $index
	start $s $e
}
if [[ $1 -eq 1 ]]; then
	run 1
elif [[ $1 -eq 2 ]]; then
	run 9
elif [[ $1 -eq 3 ]]; then
	run 17
fi
