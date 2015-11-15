# coding: utf-8

from statistics import mean, stdev
from sys import stdin

values = []
for line in stdin:
    values.append (float (line))

m = mean (values)
d = stdev (values, m)

print ("Média:", m)
print ("Desvio Padrão:", d)

