#!/bin/bash
####################################################################################
#         									   #
#	   									   #
#	Script de création automatique d'object et de règle 	                   #
#		Pour Stormshield		                                   #
#							                           #
#									           #
#	Auteur : ZanJack v1 12/05/2017			  		           #
#										   #
####################################################################################

# Prérequis:
#
# Génération d'un pair de clé ssh afin d'assurer le déroulement automatique du script
# Possèder un accès "admin" sur le firewall Stormshield souhaiter
# Syntax du fichier .csv
# host;test_1ere_ligne;10.0.250.108;First_comment;;;;;
# nethost;test_2eme_ligne;1.0.0.0;255.255.255.252;Seconde_comment;;;;
# filter;1;off;pass;test_1ere_ligne;test_2eme_ligne;2;http,ssh;

user=admin
ip="10.24.9.21"
pw=cap-syn56
path_csv=/root/file.csv

if [ -e /tmp/hote ]
then
	rm -rf /tmp/hote
fi
echo " " >> /tmp/storm.log
echo "######################## START ###################" >> /tmp/storm.log
cat $path_csv | cut -d ";" -f 1 > /tmp/hote
for chx in `cat /tmp/hote`
do
	i=$((i+1))
	if [ $chx = 'host' ]
	then
		hote=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 2`
		ip_hote=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 3`
		cmt=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 4`											  
		echo `date +"%d-%m-%y : %T"` " Création de $hote qui à pour IP $ip_hote et comme commentaire $cmt " >> /tmp/storm.log
		ssh $user@$ip 'echo CONFIG OBJECT HOST NEW name='$hote' ip='$ip_hote' resolve=static comment='$cmt' | nsrpc -f '$user':'$pw'@127.0.0.1' >> /tmp/storm.log
	elif [ $chx = 'nethost' ]
	then
		net_hote=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 2`
        ip_hote=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 3`
         mask=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 4`
		cmt=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 5` 
		echo `date +"%d-%m-%y : %T"` "Création de $net_hote qui à pour IP $ip_hote et pour Masque $mask et comme commentaire $cmt " >> /tmp/storm.log
		ssh $user@$ip 'echo CONFIG OBJECT NETWORK NEW name='$net_hote' ip='$ip_hote' mask='$mask' resolve=static comment='$cmt' | nsrpc -f '$user':'$pw'@127.0.0.1' >> /tmp/storm.log

	elif [ $chx = 'filter' ]
	then 
		slt=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 2`
		eta=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 3`
		act=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 4`
		src=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 5`
		dst=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 6`
		pst=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 7`
		p_dst=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 8`
		insp=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 9`
		log=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 10`
		cmt=`cat $path_csv | sed -n "$i"p | cut -d ";" -f 11`
		ssh $user@$ip "( echo "config filter rule insert index=$slt type=$chx state=$eta action=$act  srctarget=$src dsttarget=$dst position=$pst comment=$cmt_filt" ; echo  "config filter rule update dstport=$p_dst index=$slt global=0 type=$chx position=$pst comment=$cmt_filt" ; echo  "config filter rule update state=$eta action=$act inspection=$insp loglevel=$log index=$slt global=0 type=$chx position=$pst comment=$cmt" ; echo  "config filter activate" ; echo  "config slot activate type=$chx slot=$slt" ;  echo "QUIT" ) | nsrpc -f $user:$pw@127.0.0.1"  >/tmp/storm.log
		echo `date +"%d-%m-%y : %T"` "Création de la règle suivante SRC:$src DST:$dst via $p_dst en position $pst et comme commentaire $cmt " >> /tmp/storm.log
	fi
		echo "######################## Taches $i Execute ###################" >> /tmp/storm.log
done

echo "######################## END ###################" >> /tmp/storm.log

