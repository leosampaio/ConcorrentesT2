#!/bin/sh

roda_seq () {
	time -a -o "$1".seq_times -f '%e' ./smooth "$1" --dont-save-image "$2"
}
roda_parallel () {
	time -a -o "$1".parallel_times -f '%e' mpirun -np 4 -hostfile hostfile ./smooth "$1" --dont-save-image --parallel "$2"
}

for f in $(ls *{.tiff,.bmp,.jpg,jp2} 2> /dev/null); do
	roda_seq $f
	roda_parallel $f
done
