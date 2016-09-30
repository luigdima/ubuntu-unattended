# Unattended Ubuntu ISO Maker

Esta versión del script original de **Rinck Sonnenberg (Netson)** ha sido adaptada para facilitar su uso en entornos de laboratorio y comprensión didáctica. Esta versión corrige algunos problemas de incompatibilida en el archivo 'seed' referentes a la versión de Ubuntu 16.04.1 Server. También se modifica el archivo 'isolinux' con el fin de solventar el fallo de espera de entrada en la selección de lenguaje.

Adaptación realizada por **Luis Ignacio Díaz Martínez (luigdima)**

Original code by: **Rinck Sonnenberg (Netson)**

## Compatibility

The script supports the following Ubuntu:

* Ubuntu 16.04.1 Server LTS amd64 - Xenial Xerus

This script has been tested on and with these three versions as well, but I see no reason why it shouldn't work with other Ubuntu editions. Other editions would require minor changes to the script though.

## Usage

* Antes de empezar necesitaremos tener la imagen ISO en el MISMO directorio donde ejecutamos el script.
* From your command line, run the following commands:

```
$ wget https://raw.githubusercontent.com/luigdima/ubuntu-unattended/master/create-unattended-iso.sh
$ chmod +x create-unattended-iso.sh
$ sudo ./create-unattended-iso.sh
```
## License
MIT
