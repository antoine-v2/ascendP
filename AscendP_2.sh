#! /bin/bash
# AscendP.sh
# cree 2015/02/15 - maj 2015/02/21
# ce script retrace l'ascendance d'un processus (remonte la chaîne
# des processus parents) ; on fait une "photo" de ps qu'on stocke
# dans un fichier et qu'on analyse ensuite.

set -u

#================================================================

function nomFic {
	# définir le nom du fichier de sortie temporaire, et son nom définitif
	FIC_TMP="AscendProcessus_"$1"_"
	FIC_DEF=$FIC_TMP$(date +%Y%m%d_%H%M%S)
	FIC_TMP=$FIC_DEF"_tmp"
	# définir le nom du fichier temporaire qui contiendra résultat ps
	FIC_TMP_PS=$FIC_DEF"_ps_tmp"
	#printf "FIC_TMP : $FIC_TMP\n"
	#printf "FIC_DEF : $FIC_DEF\n"
	#printf "FIC_TMP_PS : $FIC_TMP_PS\n"
}

function valNombre {
	# vérifier que l'argument transmis est un nombre entier non signé
	printf "$1" | grep "^[[:digit:]]\+$"
	return "$?"
}

function quitter {
	# redonner à l'IFS sa valeur initiale
	IFS=$IFS_ORIG
	# supprimer le fichier temporaire, s'il existe
	if [ -f $FIC_TMP ] ; then
		rm -f $FIC_TMP
	fi
	# supprimer le fichier temporaire "ps", s'il existe
	if [ -f $FIC_TMP_PS ] ; then
		rm -f $FIC_TMP_PS
	fi
	exit $1
}

#================================================================

# stocker la valeur initiale de l'IFS, puis le modifier
IFS_ORIG=$IFS
IFS=$'\n'

# vérifier le nombre d'arguments reçus
if [ $# -ne 1 ] ; then
	printf "nombre d'arguments incorrect, 1 attendu.\n" >&2
	quitter 1
fi

# vérifier que $1 est un identifiant de PID potentiel (nombre)
valNombre $1
#echo "valeur retour de valNombre : $?"
if [ $? -ne 0 ] ; then
	printf "l'argument n'est pas un nombre.\n" >&2
	quitter 2
fi

nomFic $1
# stocker dans le fichier temporaire, date/heure courante
date +"date/heure : %d/%m/%Y %H:%M:%S" > $FIC_TMP

# le fichier $FIC_TMP_PS va contenir le résultat de la commande ps.
# il sera supprimé à la fin du script.
ps -ef | sed "s/  */ /g" | cut -f1,2,3,5,8 -d " " > $FIC_TMP_PS

# définir le motif qui correspond à : 
# en début de ligne : nom d'utilisateur, espace, PID, espace, PPID
MOTIF_LOGNAME="\([[:alnum:]]\|[[:punct:]]\)\+"
MOTIF_PID="[[:digit:]]\+"
MOTIF="^"$MOTIF_LOGNAME" "

PID_1=$1
PID_PERE=0
CPT=0
while [ "$PID_1" -ne 0 ] ; do
    #printf "    boucle 1, PID_1 : $PID_1\n"
    MOTIF_1="$MOTIF"$PID_1" "$MOTIF_PID" "
    #printf "    \$MOTIF_1 : $MOTIF_1\n"
    LIGNE=$(cat $FIC_TMP_PS | grep "$MOTIF_1")
    PID_PERE=$(echo "$LIGNE" | cut -f3 -d " ")
    PID_1=$PID_PERE
    TAB[$CPT]=$(echo "$LIGNE" | sed "s/ /    /g")
    ((CPT++))
done

# stocker la ligne d'en-têtes dans le tableau
TAB[$CPT]=$(cat $FIC_TMP_PS | head -1 | sed "s/ /    /g")

# écrire les données dans le fichier, en prenant le tableau à l'envers pour avoir dans
# le fichier, les processus les plus "vieux" en premier
while [ "$CPT" -ge 0 ] ; do
    echo ${TAB[$CPT]} >> $FIC_TMP
    ((CPT--))
done

# renommer le fichier temporaire : supprimer "_tmp"
mv $FIC_TMP $FIC_DEF

quitter 0
