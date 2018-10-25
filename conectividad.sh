#!/bin/bash


isp=`nmcli dev show | awk '/IP4.DOMAIN/ {print $2}'`
gw=`ip r | awk '/default/ {print $3}'`
dns=`nmcli dev show | awk '/IP4\.DNS/ {print $2}'`
errors=0

subject="Conectividad a Dominio $2"
mailAddress="$3"

# Probar Router
function router
{
    if [ "$gw" != "" ] 
    then
        (ping -q -c 4 $gw > /dev/null && return 0) || (echo "Problemas con el Gateway" && return 1)
    fi
}

# Probar ISP
function isp
{
    (ping -q -c 4 $isp > /dev/null && return 0) || (echo "El ISP no responde" && return 1)
}

# Probar DNS
function dns
{
    for i in $dns
    do 
        ping -q -c 4 $i > /dev/null
        if [ $? -eq 0 ]
        then
            return 0
        fi
    done

    echo "No se pueden alcanzar los servidores DNS"
    return 1
}

# Probar conectividad a dominio
function domain_connectivity()
{
    (ping -q -c 4 "$1" > /dev/null && return 0) || (echo "El dominio" $1 "no puede ser alcanzado" && return 1)
}

# Probar estado del dominio
function domain_state()
{
    http=`curl -s --max-time 4 -I $1 | awk 'NR == 1'`
    http2=`echo $http | awk '{ print $2 }'`

    if [ "$http" != "" ]
    then
        
        if [ "${http2:0:1}" != "2" ] && [ "${http2:0:1}" != "3" ]
        then
            echo "Hay algo mal con la conexión HTTP al dominio $2 $http"
            sendmutt "Hay algo mal con la conexión HTTP al dominio $2 $http"
            return 1
        else
            return 0
        fi
    else
        return 2
    fi
}

function sendlocal()
{
    notify-send "$subject" "$1" > /dev/null && echo "Notificación mostrada en pantalla" || echo "Notificación no mostrada"
}

function sendmutt()
{
    echo "$1" | mutt -s "$subject" -e "my_hdr From:$mailAddress" -- "$mailAddress" > /dev/null && echo "Correo enviado" || sendlocal "$1"
    date
}

if [ "$1" = "DAEMON" ]
then
    trap '' INT
    cd /tmp
    domainName=$2
    while true 
    do
        domain_connectivity "$domainName"
        errors=$?
        if [ $errors -eq 1 ]
        then
            
            domain_state "$domainName"
            errors=$?

            if [ $errors -eq 2 ]
            then
                router
                errors=$?

                if [ $errors -eq 0 ]
                then
                    dns
                    errors=$?
                    if [ $errors -eq 1 ]
                    then
                        isp
                        errors=$?
                        if [ $errors -eq 1 ]
                        then
                            sendmutt "No se puede alcanzar el proveedor de servicios."
                            break
                        fi
                        sendmutt "No se pueden alcanzar los servidores DNS."
                        break
                    fi

                    sendmutt "No existe el dominio $domainName"
                    break
                fi

                sendmutt "No se pueden alcanzar el Gateway o hay problemas con la conexión física."
                break
            fi

            if [ $errors -eq 1 ]
            then
                break
            fi
        fi

        sleep 60
        # echo "Todo Bien"
        # break
        
    done
    exit 0
fi

export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
umask 022
nohup setsid $0 DAEMON $* 2>~/conectividad.err >~/conectividad.log &