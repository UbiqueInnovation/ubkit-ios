#!/bin/bash

# The puropouse of this script is to open a url if it exists


usage()
{
    echo "usage: openURL [-p, --path] | [-h, --help]"
}

path=

while [ "$1" != "" ]; do
    case $1 in
        -p | --path )           shift
                                path=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done


if [ -e "$path" ]; then
	# File does not exist
    echo "Documentation was not found in $path"
    exit 1
else 
	# The file exists and can be opened
    open $path
fi 
