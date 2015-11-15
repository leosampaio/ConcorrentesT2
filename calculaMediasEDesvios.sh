#!/bin/sh

for seq in $(ls tempos/*.seq_times); do
	echo "$seq:"
	python mediaEDesvio.py < "$seq"
	echo
done
