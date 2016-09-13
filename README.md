# Script Manager

Copyright (C) Brault François - Mozilla Public Licence 2.0

Download and execute list of scripts defined in scripts.list

ps : You can create your personel script server.

## SYNOPSIS :

./script-manager.sh [-y] [-u url] [-s text]

## OPTIONS :

#####-y 
Automatic yes to prompts. Assume "yes" as answer to all prompts and run non-interactively

#####-u url
Url of scripts folder
 
#####-s text 
List of scripts folder (separated by a space)

## EXEMPLES :

wget --no-check-certificate https://raw.githubusercontent.com/Paco112/script-manager/master/script-manager.sh

chmod +x script-manager.sh

##### Execute all scripts in script.list with name "scripts_vmware" without prompt (optimise vmware debian 8 virtual machine) :
./script-manager.sh -y -s vmware

##### Download script.list from this repo and asks the user to choose the scripts to run from those available :
./script-manager.sh
