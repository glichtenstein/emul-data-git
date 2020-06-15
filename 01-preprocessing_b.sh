#!/usr/bin/env  bash

#<><><><><><><><><><><><><><><><><><><>
# SCRIPT BÁSICO PARA EL CLUSTER BIOINFO
#<><><><><><><><><><><><><><><><><><><>

#----------------------------------------------------------
# DIRECTIVAS PARA SLURM
#----------------------------------------------------------
#SBATCH --job-name=trimmo      # (Nombre de ID del trabajo)
#SBATCH --partition=CLUSTER    # (especifica grupo de nodos)
#SBATCH --nodes=1              # (cantidad de nodos)
#SBATCH --cpus-per-task=2      # (cantidad de CPUs, = 12)
#SBATCH --mem=10G              # (mínima RAM a usar, = 62G)
#SBATCH --time=02:00:00        # (tiempo de ejecución)
#SBATCH --output=slurm.%j.out  # (standard out)
#SBATCH --error=slurm.%j.err   # (standard error)

#----------------------------------------------------------
# CARGAR MODULES Y/O ENVIRONMENTS
----------------------------------------------------------
source activate cutadapt

########################################################################
# CUT MAXI COMBO
########################################################################

#FOLDER VARIABLES to use later on
WORKDIR="/share/databases/rawdata/cucher/Qiagen_2020/01-Reads/1-Raw/";
ADAPTERS="/share/databases/rawdata/cucher/Qiagen_2020/02-Reference_seqs/";
OUT="/home/cucher/Qiagen_Italia_2020/01-processed";

## An array variable to collect fastq files
arr=()

## Go to the Workdir where the fastqs are located
cd $WORKDIR

## Fill the array with the fastqs
for i in *.fastq; do arr+=( "$i" );done

# Sort the array alphanumerically by library number
arr=($(for each in ${arr[@]}; do echo $each; done | sort -k2 -t# -n));

# REMOVE POLY-A TAILS with cutadapt
count=0;
while [ $count -lt "$((${#arr[@]}))" ]; do \

	cutadapt --cores=0 --times=3 --trim-n \
	-a file:"$ADAPTERS/../polyA.fasta"  \
	-o "$OUT/polyA-${arr[$count]}" \
	"${arr[$count]}" && \

# REMOVE ADAPTORS with cutadapt
	cutadapt --cores=0 --error-rate=0.3 --trim-n --times=2 \
	-a file:"$ADAPTERS/${arr[$count]}" \
	-o "$OUT/polyA-NebNext-${arr[$count]}" \
	"$OUT/polyA-${arr[$count]}" && \

## Clean a little the $OUT folder
	rm "$OUT/polyA-${arr[$count]}"; \
	for fw in $OUT/polyA-NebNext-*; do rename 's/#/X/' $fw; done && \
	for fw in $OUT/polyA-NebNext-*; do rename 's/_1.fastq/.fastq/' $fw; done && \
	(( count++ ));
done
########################################################################
