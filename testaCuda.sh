#!/bin/sh

roda_cuda () {
	time -a -o "$1".cuda_times_"$2" -f '%e' ./cudaSmooth "$1" "$2" --dont-save-image "$3"
}

# roda as preto e brancas
echo Teste das preto e brancas
for i in $(seq 10); do
	echo "$i\n=="
	for f in $(ls gray/*.jpg 2> /dev/null); do
		echo -n "\t'$f' "
		for j in $(cat numThreads.txt); do
			echo -n " [$j]"
			roda_cuda $f $j --black-and-white
		done

		echo
	done
done
echo Fim das preto e brancas

# roda as coloridas
echo Teste das coloridas
for i in $(seq 10); do
	echo "$i\n=="
	for f in $(ls rgb/*.jpg 2> /dev/null); do
		echo -n "\t'$f' "
		for j in $(cat numThreads.txt); do
			echo -n " [$j]"
			roda_cuda $f $j
		done

		echo
	done
done
echo Fim das coloridas
