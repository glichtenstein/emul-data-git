#!/usr/bin/env bash
#
########################################################################
## Parametros del QSUB ##
########################################################################
#PBS -V
#PBS -N bowtie_emul
#PBS -l nodes=1:ppn=3:impam2
#PBS -M glichtenstein@fmed.uba.ar
#PBS -m abe
cd $PBS_O_WORKDIR
########################################################################

########################################################################
## OBJETIVO
# Usando los fasta que se obtienen con el mapper (que están colapsados) 
# mapear con bowtie al genoma de referencia de emul
########################################################################

########################################################################
WORKDIR="/home/cucher/BigData/sanger_RNAseq/";
########################################################################

########################################################################
## indexed reference genome
ebwt="$WORKDIR/02-reference_seqs/genomes/emu_v4_complete_genome_cluster";
########################################################################

########################################################################
## crear array para contener los archivos fasta
########################################################################
arrFasta=();

## entrar a carpeta de los fasta del mapper
cd "$WORKDIR/03-miRNA_search/mapper_output";

## fill the array with the fasta's
for i in *.fasta; do arrFasta+=( "$i" );done

#sort the array alphanumerically by library number
arrFasta=($(for each in ${arrFasta[@]}; do echo $each; done | sort -k2 -t# -n));

########################################################################
## donde van a ir los outputs del bowtie
########################################################################
output_sam="$WORKDIR/04-tRNA_search/01-bowtie/bowtie_output";
aligned_reads="$WORKDIR/04-tRNA_search/01-bowtie/bowtie_output";

########################################################################
## ejecutar bowtie (versión 1)
########################################################################
# despues de bowtie renombrar y convertir fasta a tabular fasta
count=0;

while [ $count -lt "${#arrFasta[@]}" ];
do
 bowtie -v3 \
 --sam --best --time --threads 8 --verbose \
 --al $aligned_reads/${arrFasta[ $count ]}.emul.fa \
 $ebwt \
 -f "$WORKDIR/03-miRNA_search/mapper_output/${arrFasta[ $count ]}" "$output_sam/${arrFasta[ $count ]}.emul.sam";
 /share/apps/miniconda3/bin/fasta_formatter -t -i $output_sam/${arrFasta[ $count ]}.emul.fa -o $output_sam/${arrFasta[ $count ]}.emul.tab;
 rename 's/.fasta//' $output_sam/${arrFasta[ $count ]}.emul.tab
 rename 's/.fasta//' $output_sam/${arrFasta[ $count ]}.emul.fa;
 rename 's/.fasta//' $output_sam/${arrFasta[ $count ]}.emul.sam;
 (( count++ ));
done
########################################################################
