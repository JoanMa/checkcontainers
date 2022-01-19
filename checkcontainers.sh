#!/bin/bash
# version b0.1

#config
XARXA='/etc/sysconfig/network-scripts/'
TOTAL=$(ls /etc/sysconfig/network-scripts/ifcfg-eth0:* | wc -l)
MAXDOCKER=20

function NetejaInterficies {
        for x in $(ls ${XARXA}ifcfg-eth0:*);
        do
                if docker ps | awk '{print $12}' |grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep $(cat $x | grep IPADDR |grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b");  then
                        echo $x "exist, so i ignore"
                else
                        echo $x "no docker found with this interface i proceed to clean it";
                        rm -f $x
                fi
        done
}

function ComproboContainers {
        if [ $(docker ps | wc -l) -ge ${MAXDOCKER} ]; then
                echo "this node have more containers than ${MAXDOCKER}"
                for x in $(docker ps | awk '{print $14}' |grep -v ^$);
                do
                        if grep $x contenidors; then
                                echo "$x allowed"
                        else
                                echo "$x Not found, stoping"
                                docker stop $x
                        fi
                done
        else
                echo "this node can allocate more containers"
                echo " --- checking running containers"
                for x in $(docker ps | awk '{print $14}' |grep -v ^$);
                do
                        echo "checking if $x is into database"
                        if grep $x contenidors; then
                                echo "$x found into database"
                        else
                                echo "$x Not found, i proceed to add"
                                echo $x >> ./contenidors
                        fi
                done

                echo "--- Reviewing and cleaning database"
                for x in $(cat contenidors);
                do
                        if docker ps | awk '{print $14}' |grep -v ^$ | grep $x; then
                                echo "keep $x on database"
                        else
                                echo "$x not present cleaning"
                                sed -i "/${x}/d" ./contenidors
                        fi
                done
        fi
}



#Runing script
        echo "Starting checks $(date +"%Y%m%d-%H%M%S")"
        #Container tasks
        echo "checking if this host have more containers that allowed"
        ComproboContainers

        #Runing clean tasks
        echo "Starting cleaning interface config"
        NetejaInterficies
