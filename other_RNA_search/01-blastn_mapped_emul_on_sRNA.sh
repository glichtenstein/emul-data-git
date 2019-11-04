#!/usr/bin/env bash

########################################################################
## Parametros del QSUB ##
########################################################################
#PBS -V
#PBS -N blastn_emul
#PBS -l nodes=1:ppn=6:impam2
#PBS -M glichtenstein@fmed.uba.ar
#PBS -m abe
cd $PBS_O_WORKDIR
########################################################################

########################################################################
# Variables declaradas
########################################################################
WORKDIR="/home/cucher/BigData/sanger_RNAseq";

# carpeta con fastas
QUERIES="$WORKDIR/04-tRNA_search/01-bowtie/bowtie_output";

# DataBase
DATABASE="$WORKDIR/02-reference_seqs/tRNAs/emul_db.fasta";

# Outputs folder:
OUTPUT="$WORKDIR/04-tRNA_search/02-blastn/blastn_output";
########################################################################

########################################################################
## crear array para contener los archivos fasta
########################################################################
arrfasta=();

## entrar a carpeta de los fasta que vienen de mapear con bowtie
cd "$QUERIES";

## fill the array with the fasta's
for i in *.emul.fa; do arrfasta+=( "$i" );done

#sort the array alphanumerically by library number
arrfasta=($(for each in ${arrfasta[@]}; do echo $each; done | sort -k2 -t# -n));

########################################################################
# BLASTN-SHORT
########################################################################
count=0;

while [ $count -lt "${#arrfasta[@]}" ];
do
 blastn \
	-task "blastn-short" \
	-query "${arrfasta[ $count ]}" \
	-db "$DATABASE" \
	-out "$OUTPUT/${arrfasta[ $count ]}.blastn" \
	-outfmt "6 qseqid sseqid pident qstart qend qlen length qcovhsp sstrand sstart send slen mismatch gapopen evalue qseq" \
	-max_target_seqs "1" \
	-evalue "0.01" \
	-num_threads "8";
	rename 's/.emul.fa.blastn/.emul.blastn/' "$OUTPUT/${arrfasta[ $count ]}.blastn";
	(( count++ ));

done
########################################################################
