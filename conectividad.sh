#!/bin/bash


isp=`nmcli dev show | awk '/IP4.DOMAIN/ {print $2}'`
gw=`ip r | awk '/default/ {print $3}'`
dns=`nmcli dev show | awk '/IP4\.DNS/ {print $2}'`

# Probar Router
if [ "$gw" != "" ] 
then
    ping -q -c 4 $gw > /dev/null && echo "Router fino" || echo "Router malo" ;
else
    echo "No gateway available"
fi

# Probar ISP
ping -q -c 4 $isp > /dev/null && echo "Ese ISP esta es pepa menol -Andrea 2018" || echo "ISP malo" ;

# Probar DNS
for i in $dns
    do 
        ping -q -c 4 $i > /dev/null && echo "dns: $i fino" || echo "dns: $i malo"
done

# Probar conectividad a dominio
ping -q -c 4 $1 > /dev/null && echo "Ese dominio esta es pepa menol -Andrea 2018" || echo "Que es eso de $1 hermano? -Andrea 2018" ;

# Probar estado del dominio
http=`curl -s --max-time 4 -I $1 | awk 'NR == 1'` 

if [ "$http" != "" ]
then
    echo "Fino encontramos $http"
else
    echo "grueso encontramos un 404"
fi