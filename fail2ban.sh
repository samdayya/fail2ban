#!/bin/bash

# Script per mostrar totes les IP bloquejades de tots els jails de Fail2ban amb timestamps en format humà i geolocalització

# Accedir a la base de dades SQLite
db_path="/var/lib/fail2ban/fail2ban.sqlite3"

# Verificar si la base de dades existeix
if [ ! -f "$db_path" ]; then
    echo "La base de dades de Fail2ban no existeix a $db_path"
    exit 1
fi

# Funció per obtenir la informació geogràfica de l'IP
get_geo_info() {
    local ip="$1"
    local geo_info=$(curl -s "https://ipinfo.io/$ip/json")
    
    if [ $? -eq 0 ]; then
        echo "$geo_info" | jq -r '.country, .region, .city'
    else
        echo "Desconegut"
    fi
}

# Encapsular la consulta a SQLite
result=$(sqlite3 "$db_path" "SELECT jail, ip, timeofban, bantime FROM bans;")

# Comprovar si s'han obtingut resultats
if [ -z "$result" ]; then
    echo "No hi ha IP bloquejades."
    exit 0
fi

# Mostrar capçalera
printf "%-20s %-20s %-25s %-10s %-10s %-20s %-10s\n" "Jail" "IP" "Time of Ban" "Ban Time" "Country" "Region" "City"
echo "------------------------------------"

# Processar els resultats
echo "$result" | while IFS='|' read -r jail ip timeofban bantime; do
    # Convertir el timestamp a format humà
    human_time=$(date -d @"$timeofban" +"%Y-%m-%d %H:%M:%S")
    
    # Obtenir informació geogràfica de l'IP
    geo_info=$(get_geo_info "$ip")
    
    # Separar la informació geogràfica
    country=$(echo "$geo_info" | awk 'NR==1 {print}')
    region=$(echo "$geo_info" | awk 'NR==2 {print}')
    city=$(echo "$geo_info" | awk 'NR==3 {print}')
    
    # Mostrar resultats amb alineació
    printf "%-20s %-20s %-25s %-10s %-10s %-20s %-10s\n" "$jail" "$ip" "$human_time" "$bantime" "$country" "$region" "$city"
done
