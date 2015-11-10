#!/bin/bash


gray="
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042500_042599/ESP_042527_1555/ESP_042527_1555_RED.NOMAP.browse.jpg
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042500_042599/ESP_042513_1875/ESP_042513_1875_RED.NOMAP.browse.jpg
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042500_042599/ESP_042565_2575/ESP_042565_2575_RED.NOMAP.browse.jpg
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042500_042599/ESP_042585_1715/ESP_042585_1715_RED.NOMAP.browse.jpg"

rgb="
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042600_042699/ESP_042686_1360/ESP_042686_1360_RGB.NOMAP.browse.jpg
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042600_042699/ESP_042674_1775/ESP_042674_1775_RGB.NOMAP.browse.jpg
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042600_042699/ESP_042610_1990/ESP_042610_1990_RGB.NOMAP.browse.jpg
http://hirise-pds.lpl.arizona.edu/download/PDS/EXTRAS/RDR/ESP/ORB_042500_042599/ESP_042556_1985/ESP_042556_1985_RGB.NOMAP.browse.jpg"

# imagens preto e brancas
mkdir -p gray
cd gray
for img in $gray; do
	wget $img
done
cd ..

# imagens coloridas
mkdir -p rgb
cd rgb
for img in $rgb; do
	wget $img
done
cd ..
