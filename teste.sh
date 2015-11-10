#!/bin/sh

roda_seq () {
	time -a -o "$1".seq_times -f '%e' ./smooth "$1" --dont-save-image "$2"
}
roda_parallel () {
	time -a -o "$1".parallel_times -f '%e' mpirun -np 4 -hostfile hostfile ./smooth "$1" --dont-save-image --parallel "$2"
}

# roda as preto e brancas
echo Teste das preto e brancas
for i in $(seq 10); do
	echo -e "$i\n=="
	for f in $(ls gray/*.jpg 2> /dev/null); do
		echo -en "\t'$f' [sequencial]"
		roda_seq $f --black-and-white
		echo -n " [paralelo]"
		roda_parallel $f --black-and-white
		echo
	done
done
echo Fim das preto e brancas

# roda as coloridas
echo Teste das coloridas
for i in $(seq 10); do
	echo -e "$i\n=="
	for f in $(ls rgb/*.jpg 2> /dev/null); do
		echo -en "\t'$f' [sequencial]"
		roda_seq $f
		echo -n " [paralelo]"
		roda_parallel $f
		echo
	done
done
echo Fim das coloridas
