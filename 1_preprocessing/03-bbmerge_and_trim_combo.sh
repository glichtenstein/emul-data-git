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
#PBS -N BBtrimCombo
#
############################################################################
## 2) Configurar los recursos que quiero reservar en el cluster            #
############################################################################
#
#PBS -l nodes=1:ppn=1:impam2
#PBS -q bmhid
#
############################################################################
## 3) notificaciónes del qsub via email al comenzar y terminar el proceso: #
############################################################################
#PBS -M glichtenstein@fmed.uba.ar
#PBS -m abe
#
########################################################################
# BBMERGE and TRIMOMATIC COMBO
########################################################################
WORKDIR="/home/cucher/BigData/sanger_RNAseq/01-reads/3-preprocessed";
OUT="/home/cucher/BigData/sanger_RNAseq/01-reads/3-preprocessed/final";
#
## Declare arrays to collect fastq files
fwReads=();
rvReads=();
#
## Fill the array with the Forward fastqs
cd $WORKDIR/forward;
for fw in *.fastq; do fwReads+=( "$fw" ); done
#
## Fill the array with the Reverse fastqs
cd $WORKDIR/reverse;
for rv in *.fastq; do rvReads+=( "$rv" ); done
#
## Sort the arrays alphanumerically by library number
fwReads=($(for each in ${fwReads[@]}; do echo $each; done | sort -k2 -t# -n));
#
rvReads=($(for each in ${rvReads[@]}; do echo $each; done | sort -k2 -t# -n));
#
###################################################################
## RePair, BBmerge FW & RV reads, and Trimm by Quality and Length
###################################################################
count=0;
while [ $count -lt "$((${#fwReads[@]}))" ]; do \
	## Concatenate forward and reverse reads in one single file
	cat "$WORKDIR/forward/${fwReads[$count]}" "$WORKDIR/reverse/${rvReads[$count]}" > "$OUT/paired-${fwReads[$count]}" && \
	#
	###################################################################
#---## RE-PAIR the pairs and SINGLE the singletons
	###################################################################
	repair.sh in="$OUT/paired-${fwReads[$count]}" out="$OUT/repaired-${fwReads[$count]}" outs="$OUT/singletons-${fwReads[$count]}" && \
	#
	## Clean folder
	#rm "$OUT/paired-${fwReads[$count]}" && \
	###################################################################
#---## BBMERGE - with custom processing parameters
	###################################################################
	bbmerge.sh minoverlap0=8 minoverlap=12 mininsert=18 mininsert0=17 in="$OUT/repaired-${fwReads[$count]}" out="$OUT/bbmerged-${fwReads[$count]}" outu1="$OUT/unmerged-${fwReads[$count]}" ihist="$OUT/${fwReads[$count]}".ihist && \
	## Clean folder
	#rm "$OUT/repaired-${fwReads[$count]}" && \
	#
	#################################################################################
#---## Concatenate the bbmerged reads with the unmerged and singletons into one file.
	#################################################################################
	cat "$OUT/bbmerged-${fwReads[$count]}" "$OUT/unmerged-${fwReads[$count]}" "$OUT/singletons-${fwReads[$count]}" > "$OUT/bbfinal-${fwReads[$count]}" && \
	### Clean folder
	#rm "$OUT/bbmerged-${fwReads[$count]}";rm "$OUT/unmerged-${fwReads[$count]}";rm "$OUT/singletons-${fwReads[$count]}" && \
	#
	###################################################################
#---## TRIM BY QUALITY with trimmOmatic
	###################################################################
	#java -jar /share/apps/Trimmomatic-0.36/trimmomatic-0.36.jar SE \#
	trimmomatic SE \
	-threads 6 \
	"$OUT/bbfinal-${fwReads[$count]}" \
	"$OUT/trimmed-${fwReads[$count]}" \
	SLIDINGWINDOW:4:20 MINLEN:18 && \
	### Clean folder
	#rm "$OUT/bbfinal-${fwReads[$count]}" && \
	#
	## RENAME final output with prettier names
	rename 's/trimmed-polyA-NebNext/final/' "$OUT/trimmed-${fwReads[$count]}";
	(( count++ ));
done
###################################################################
# Clean FW and RV Folders if low on space
###################################################################
#rm $WORKDIR/reverse/*;
#rm $WORKDIR/forward/*;
#
###################################################################
# Order final reads in FW-FW (sense-sense) direction
###################################################################
cd $OUT;
for i in final-*.fastq;
do
# reverse complement reverse reads (/2 reads)
# isolate unmerged and singletons forward reads:
grep -A3 -P "/1$" --no-group-separator $i > forward-$i;
# isolate unmerged and singletons reverse reads:
grep -A3 -P "/2$" --no-group-separator $i > reverse-$i;
# rev-complement /2 reads
fastx_reverse_complement -i reverse-$i -o RC-reverse-$i;
# merge forward with RC-reverse reads
cat RC-reverse-$i forward-$i > sense-$i; done
###################################################################
## Run FASTQC on final samples
###################################################################
mkdir -p $OUT/fastqc;
for i in $OUT/*.fastq; do fastqc $i -o fastqc/; done
###################################################################
