#!/bin/bash
DOMAINNAME=$1
ZONEDIR="/etc/bind/zones"
BINDZONECONF="/etc/bind/named.conf.zones"
KEYDIR="/etc/bind/keys"

unset SECCHECK

# help/usage
if [ "$1" = "-h" ]||[ "$1" = "--help" ]||[ -z "$1" ]; then
    echo "Usage: bind-load-zone [DOMAIN]
This script is used for signed or non-signed domains (taken as an argument). 
It does the following:
    1) Increments the serial of the domain's zone file
    2) Checks if the domain is signed by looking in $BINDZONECONF
    3) Re-signs the domain (if it was already signed)
    4) Reloads BIND for the domain (rndc reload [DOMAIN])

    -h, --help Display this help message and exit."
    exit 1
fi

SECCHECK=$(grep $DOMAINNAME $BINDZONECONF | grep -v \/\/.*signed | grep $DOMAINNAME.signed)

if [ -z "$SECCHECK" ]; then
    
    # UNSIGNED
    echo -e "\n$DOMAINNAME is not a signed zone.\n"
    SERIAL=$(/usr/sbin/named-checkzone "$DOMAINNAME" $ZONEDIR/$DOMAINNAME | grep "loaded serial" | grep -o '[0-9]*')
    # Verify before proceeding with any action.
    echo "$DOMAINNAME serial $SERIAL will be incremented to $(($SERIAL+1))."
    echo "BIND will load changes for $DOMAINNAME."
    read -p "Proceed? (Y/n) " -n 1 -r 

    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then 
        echo -e "\nExiting. No changes were made."
        exit 1
    else
        echo -e "\nIncrementing serial to $(($SERIAL+1))."
        sed -i 's/'$SERIAL'/'$(($SERIAL+1))'/' $ZONEDIR/$DOMAINNAME
        echo "Reloading BIND for $DOMAINNAME"
        rndc reload $DOMAINNAME
        exit 0
    fi

else

    # SIGNED
    echo -e "\n$DOMAINNAME is a signed zone.\n"
    SERIAL=$(/usr/sbin/named-checkzone "$DOMAINNAME" $ZONEDIR/$DOMAINNAME | grep "loaded serial" | grep -o '[0-9]*')
    # Verify before proceeding with any action.
    echo "$DOMAINNAME serial $SERIAL will be incremented to $(($SERIAL+1))"
    echo "$DOMAINNAME will be signed using dnssec-signzone."
    echo "Bind will load changes for $DOMAINNAME."
    read -p "Proceed? (Y/n) " -n 1 -r

    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo -e "\nExiting. No changes were made."
        exit 1
    else

        echo -e "\nIncrementing serial to $(($SERIAL+1))."
        # Using sed instead of dnssec-signzone to increment unsigned zone file.
        # This way the signed and unsigned files keep the same serial.
        sed -i 's/'$SERIAL'/'$(($SERIAL+1))'/' $ZONEDIR/$DOMAINNAME
        echo "Signing zone for $DOMAINNAME"

        # Note -N keep option for serial
        # Note -K keydir option, required for our config
        /usr/sbin/dnssec-signzone -K $KEYDIR -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) -N keep -o "$DOMAINNAME" -t "$ZONEDIR/$DOMAINNAME"
        echo "Reloading BIND for $DOMAINNAME"
        rndc reload $DOMAINNAME
        exit 0
    fi
fi
