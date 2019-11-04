#!/usr/bin/env	bash

########################################################################
## Parametros del QSUB ##
########################################################################
#PBS -V
#PBS -N blast_parser_mus
#PBS -l nodes=1:ppn=1:impam2
#PBS -M glichtenstein@fmed.uba.ar
#PBS -m abe
#PBS -q bmhid
########################################################################

########################################################################
WORKDIR="/home/cucher/BigData/sanger_RNAseq/04-tRNA_search/02-blastn/blastn_output";
DATABASE="/home/cucher/BigData/sanger_RNAseq/02-reference_seqs/tRNAs/mus_musculus_db.fasta";
bowtieOutput="/home/cucher/BigData/sanger_RNAseq/04-tRNA_search/01-bowtie/bowtie_output";
blastnOutput="/home/cucher/BigData/sanger_RNAseq/04-tRNA_search/02-blastn/blastn_output";
parsedOutput="/home/cucher/BigData/sanger_RNAseq/04-tRNA_search/02-blastn/parsed_blastn_output";
########################################################################

########################################################################
# extract sseqid ( blastn output column 2) to a temp file
########################################################################
# entrar a carpeta de los outputs de blast
cd "$WORKDIR";

# crear array para contener los outputs de blast
blastarr=();

# fill the array with the emul blast output files
for i in *.mus.blastn; do blastarr+=( "$i" );done

# sort the array alphanumerically by library number
blastarr=($(for each in ${blastarr[@]}; do echo $each; done | sort -k2 -t# -n));

# extract sseqid (column 2) to a temp file
count=0;
while [ $count -lt "$((${#blastarr[@]}))" ]; do \
	awk '{OFS="\t";print $2}' "$WORKDIR/${blastarr[ $count ]}" > "$WORKDIR/${blastarr[ $count ]}".sseqid_col; \
	(( count++ ));
done

# Crear array para contener los sseqid_col
sseqidarr=();

# Fill the array with the sseqid columns
for i in *.mus.blastn.sseqid_col; do sseqidarr+=( "$i" );done

# sort the array alphanumerically by library number
sseqidarr=($(for each in ${sseqidarr[@]}; do echo $each; done | sort -k2 -t# -n));

# Search annotated IDs in the database line by line and output to a file
count=0;
while [ $count -lt "$((${#sseqidarr[@]}))" ]; do \
  while read LINE;
  do grep -w "$LINE" $DATABASE;
  done < ${sseqidarr[ $count ]} > ${sseqidarr[ $count ]}_full && \
  rm ${sseqidarr[ $count ]};
  (( count++ ));
done

########################################################################
# extract qseqid (column 1) to a temp file
########################################################################
# entrar a carpeta de los outputs de blast
cd "$WORKDIR";

# crear array para contener la columna 1 de outputs de blast
blastarr2=();

# fill the array with the emul blast output files
for i in *.mus.blastn; do blastarr2+=( "$i" );done

# sort the array alphanumerically by library number
blastarr2=($(for each in ${blastarr2[@]}; do echo $each; done | sort -k2 -t# -n));

# extract
count=0;
while [ $count -lt "$((${#blastarr2[@]}))" ]; do \
  awk '{OFS="\t";print $1}' "$WORKDIR/${blastarr2[$count]}" > "$WORKDIR/${blastarr2[$count]}".qseqid_col; \
  (( count++ ));
done;

########################################################################
# usar ids para extraer las secuencias fasta de interes
########################################################################
# entrar a carpeta de los outputs de bowtie (fastas tabulares)
cd "$bowtieOutput";

# crear array para contener los outputs de bowtie
tabarr=();

# fill the array with the tabular fasta reads
for i in *.mus.tab; do tabarr+=( "$i" );done;

# sort the array alphanumerically by library number
tabarr=($(for each in ${tabarr[@]}; do echo $each; done | sort -k2 -t# -n));

# extraer secuencia fasta de interes
count=0;
while [ $count -lt "$((${#tabarr[@]}))" ]; do \
  QUERY="${tabarr[ $count ]}"
  while read LINE;
  do grep -w "$LINE" "$QUERY";
  done < "$WORKDIR/${blastarr2[$count]}.qseqid_col" >> "$WORKDIR/${blastarr2[$count]}.qseqid_col_full";
  rm "$WORKDIR/${blastarr2[$count]}.qseqid_col";
  (( count++ ));
done;
########################################################################

########################################################################
# Replace the sseqid column for the complete sseqid and add the qseqid sequence column
########################################################################
# entrar a carpeta de los outputs de blast
cd "$WORKDIR";

# crear array para contener los sseqid y qseqids que quiero agregar a la tabla de blast original
fullsseqidarr=();
fullqseqidarr=();

# crear array para contener las tablas de outputs de blast
blastarr=();

# fill the array with the mus blast output files
for i in *.mus.blastn; do blastarr+=( "$i" );done

# fill the array with the sseqid columns
for i in *.mus.blastn.sseqid_col_full; do fullsseqidarr+=( "$i" );done

# fill the array with the qseqid columns
for i in *.mus.blastn.qseqid_col_full; do fullqseqidarr+=( "$i" );done

# Sort the arrays alphanumerically by library number
# The reads ID's and Annotation:
fullsseqidarr=($(for each in ${fullsseqidarr[@]}; do echo $each; done | sort -k2 -t# -n));
# The reads complete nucleotide sequence
fullqseqidarr=($(for each in ${fullqseqidarr[@]}; do echo $each; done | sort -k2 -t# -n));
# The blast output columns
blastarr=($(for each in ${blastarr[@]}; do echo $each; done | sort -k2 -t# -n));

########################################################################
# Search and Replace the sseqid column for full sseqid
########################################################################
count=0;
while [ $count -lt "${#fullsseqidarr[@]}" ];

do 

sseqId="${fullsseqidarr[ $count ]}";
qseqId="${fullqseqidarr[ $count ]}";
blastOut="${blastarr[ $count ]}";
tempOut1="$parsedOutput/${fullsseqidarr[ $count ]}.temp1.tab";
tempOut2="$parsedOutput/${fullqseqidarr[ $count ]}.temp2.tab"; 
tempOut3="$parsedOutput/${fullqseqidarr[ $count ]}.temp3.tab"
finalOut="$parsedOutput/${fullqseqidarr[ $count ]}.final.csv";

# incorporate Read IDs and annotations (SSEQID_FULL)
awk 'BEGIN {FS=OFS="\t"}NR == FNR {a[FNR] = $B;next}{$A = a[FNR];print $0}' B=1 A=2 \
	"$sseqId" "$blastOut" > "$tempOut1" && \

# incorporate Read nucleotide sequences
paste -d'	' "$qseqId" "$tempOut1" > "$tempOut2";

# Parse all in order and output a table with % as field separator
cat "$tempOut2" | awk 'BEGIN {FS=OFS="\t"}NR == FNR { 
	print $1,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$2 }' OFS='%' | sed -e 's/_x/%/g' | sort -rn -t $'%' -k2,2 > "$tempOut3";
 
# make the table excel importable by using tabs as field separators
cat "$parsedOutput/HEADERS" "$tempOut3" |\
sed -e 's/%/	/g' > "$finalOut";

# give prettier names to final outputs
rename 's/.mus.blastn.qseqid_col_full.final/.mus.ann.csv/' "$finalOut";

# Clean folder debris
#rm "$tempOut1";
#rm "$tempOut2";
#rm "$tempOut3";
#rm "${fullsseqidarr[ $count ]}";
#rm "${fullqseqidarr[ $count ]}";
   
(( count++ ));

done
########################################################################

printf "The script finished. Was it Ok? Please analyze, but before, take a deap breath, relax, and focus on your smile :)";
