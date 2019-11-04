#!/bin/bash
##
#PBS -V
############################################################
## MODELO DE BASH SCRIPT PARA EJECUTAR UN COMANDO MEDIANTE #
##        EL SISTEMA DE COLAS (QSUB) DEL SERVIDOR IMPAM    #
##                                                         #
##               glichtenstein@fmed.uba.ar                 #
############################################################
#
#These commands set up the Grid Environment for your job:
#
##################################################
## 1) Poner un nombre para identificar tu script #
##################################################
#
#PBS -N CutCombo-FW
#
############################################################################
## 2) Configurar los recursos que quiero reservar en el cluster            #
############################################################################
#
#PBS -l nodes=1:ppn=6:impam2
#PBS -q bmhid
#
############################################################################
## 3) notificaciónes del qsub via email al comenzar y terminar el proceso: #
############################################################################
#PBS -M glichtenstein@fmed.uba.ar
#PBS -m abe
#
################################################################################################
# CUT MAXI COMBO
#################################################################################################
#
# To run cutadapt with multi-threading activate python3 environment
export PATH=/share/apps/miniconda3/envs/python3/bin/:$PATH;
source activate python3;
#
# FOLDER VARIABLES to use later on
WORKDIR="/home/cucher/BigData/sanger_RNAseq/01-reads/1-raw/forward";
ADAPTERS="/home/cucher/BigData/sanger_RNAseq/01-reads/2-adapters/forward";
OUT="/home/cucher/BigData/sanger_RNAseq/01-reads/3-preprocessed/forward";
#
## An array variable to collect fastq files
arr=()
#
## Go to the Workdir where the fastqs are located
cd $WORKDIR
#
## Fill the array with the fastqs
for i in *.fastq; do arr+=( "$i" );done
#
# Sort the array alphanumerically by library number
arr=($(for each in ${arr[@]}; do echo $each; done | sort -k2 -t# -n));
#
# REMOVE POLY-A TAILS with cutadapt
count=0;
while [ $count -lt "$((${#arr[@]}))" ]; do \

	cutadapt --cores=0 --times=3 --trim-n \
	-a file:"$ADAPTERS/../polyA.fasta"  \
	-o "$OUT/polyA-${arr[$count]}" \
	"${arr[$count]}" && \
#
# REMOVE ADAPTORS with cutadapt
	cutadapt --cores=0 --error-rate=0.3 --trim-n --times=2 \
	-a file:"$ADAPTERS/${arr[$count]}" \
	-o "$OUT/polyA-NebNext-${arr[$count]}" \
	"$OUT/polyA-${arr[$count]}" && \
#
## Clean a little the $OUT folder
	rm "$OUT/polyA-${arr[$count]}"; \
	for fw in $OUT/polyA-NebNext-*; do rename 's/#/X/' $fw; done && \
	for fw in $OUT/polyA-NebNext-*; do rename 's/_1.fastq/.fastq/' $fw; done && \
	(( count++ ));
done
# Seguir pipeline con REVERSE READS
#################################################################################################
qsub "/home/cucher/BigData/sanger_RNAseq/01-reads/02-cutadapt_combo_reverse.sh"
