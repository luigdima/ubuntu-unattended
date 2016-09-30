#!/usr/bin/env bash


#Limpiamos ventana
clear

# Variables de entorno
tmp=$(pwd)  # destination folder to store the final iso file
currentuser="$( whoami)"

download_file="ubuntu-16.04.1-server-amd64.iso"
new_iso_name="ubuntu-16.04.1-server-amd64-unattended.iso"

seed_file="ubuntu-asix.seed"

# Definimos cola para las tareas lentas
# courtesy of http://fitnr.com/showing-a-bash-spinner.html
spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Comprobamos los paquetes necesarios
# courtesy of https://gist.github.com/JamieMason/4761049
function program_is_installed {
    # set to 1 initially
    local return_=1
    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }
    # return value
    echo $return_
}

# Imprimimos la pantalla de cabezera
echo
echo " +---------------------------------------------------+"
echo " |            UNATTENDED UBUNTU ISO MAKER            |"
echo " +---------------------------------------------------+"
echo

# ask if script runs without sudo or root priveleges
if [ $currentuser != "root" ]; then
    echo " you run this without sudo privileges or not as root"
    exit 1
fi

if [ -f /etc/timezone ]; then
  timezone=`cat /etc/timezone`
elif [ -h /etc/localtime]; then
  timezone=`readlink /etc/localtime | sed "s/\/usr\/share\/zoneinfo\///"`
else
  checksum=`md5sum /etc/localtime | cut -d' ' -f1`
  timezone=`find /usr/share/zoneinfo/ -type f -exec md5sum {} \; | grep "^$checksum" | sed "s/.*\/usr\/share\/zoneinfo\///" | head -n 1`
fi

# Realizamos las preguntas para la configuración de 'SEED'
read -ep " please enter your preferred hostname: " -i "asixsrv01" hostname
read -ep " please enter your preferred timezone: " -i "${timezone}" timezone
read -ep " please enter your preferred username: " -i "administrador" username
read -sp " please enter your preferred password: " password
printf "\n"
read -sp " confirm your preferred password: " password2
printf "\n"

# Comprobamos que el password sea correcto (Repetido)
if [[ "$password" != "$password2" ]]; then
    echo " your passwords do not match; please restart the script and try again"
    echo
    exit
fi

cd $tmp

# Instalamos los paquetes 'requeridos' (necesarios)
echo " installing required packages"
if [ $(program_is_installed "mkpasswd") -eq 0 ] || [ $(program_is_installed "mkisofs") -eq 0 ]; then
    (apt-get -y update > /dev/null 2>&1) &
    spinner $!
    (apt-get -y install whois genisoimage > /dev/null 2>&1) &
    spinner $!
fi

# Creamos los directorios de trabajo
echo " remastering your iso file"
mkdir -p $tmp
mkdir -p $tmp/iso_org
mkdir -p $tmp/iso_new

# Montamos la imagen
if grep -qs $tmp/iso_org /proc/mounts ; then
    echo " image is already mounted, continue"
else
    (mount -o loop $tmp/$download_file $tmp/iso_org > /dev/null 2>&1)
fi

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# PROCESO DE MODIFICACIÓN DESATENDIDA!!!

# Copiamos la iso en el directorio
(cp -rT $tmp/iso_org $tmp/iso_new > /dev/null 2>&1) &
spinner $!

# Seteamos el lenguaje en el instalador
cd $tmp/iso_new
echo en > $tmp/iso_new/isolinux/lang
cat $tmp/iso_new/isolinux/lang

# Copiamos el archivo SEED a la nueva ISO
cp -rT $tmp/$seed_file $tmp/iso_new/preseed/$seed_file

# Generamos la contraseña (encriptada)
pwhash=$(echo $password | mkpasswd -s -m sha-512)

# Actualizamos el fichero SEED con el comando 'sed'
# En base a las variables (preguntas) asignadas anteriormente)
sed -i "s@{{username}}@$username@g" $tmp/iso_new/preseed/$seed_file
sed -i "s@{{pwhash}}@$pwhash@g" $tmp/iso_new/preseed/$seed_file
sed -i "s@{{hostname}}@$hostname@g" $tmp/iso_new/preseed/$seed_file
sed -i "s@{{timezone}}@$timezone@g" $tmp/iso_new/preseed/$seed_file

# Calculamos la suma de verificación del archivo
seed_checksum=$(md5sum $tmp/iso_new/preseed/$seed_file)

# IMPORTANTE: Añadimos las lineas del menú  de arranque!
sed -i "s@default install@default autoinstall@g" $tmp/iso_new/isolinux/txt.cfg

sed -i "/label install/ilabel autoinstall\n\
  menu label ^Autoinstall Ubuntu Server\n\
  kernel /install/vmlinuz\n\
  append file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz auto=true priority=critical preseed/file=/cdrom/preseed/ubuntu-asix.seed preseed/file/checksum=$seed_checksum --\n" $tmp/iso_new/isolinux/txt.cfg

# IMPORTANTE: Añadimos 'timeout' en isolinux para arranque automático
sed -i "s@timeout 0@timeout 1@g" $tmp/iso_new/isolinux/isolinux.cfg

echo " creating the remastered iso"
cd $tmp/iso_new
(mkisofs -D -r -V "UNATTENDED_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $tmp/$new_iso_name . > /dev/null 2>&1) &
spinner $!

# Desmontamos iso y eliminamos directorios de trabajo
umount $tmp/iso_org
rm -rf $tmp/iso_new
rm -rf $tmp/iso_org

# Mostramos información (resumen) de usuario
echo " -----"
echo " finished remastering your ubuntu iso file"
echo " the new file is located at: $tmp/$new_iso_name"
echo " your username is: $username"
echo " your password is: $password"
echo " your hostname is: $hostname"
echo " your timezone is: $timezone"
echo

# Libreramos variables
unset username
unset password
unset hostname
unset timezone
unset pwhash
unset download_file
unset new_iso_name
unset tmp
unset seed_file
