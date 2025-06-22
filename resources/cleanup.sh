#!/bin/bash
apt-get purge gnupg software-properties-common -y --autoremove --allow-remove-essential
rm -vrf /etc/apt/sources.list.d/jellyfin.sources
rm -vrf /var/lib/apt/lists/*
apt-get clean autoclean -y
apt-get autoremove -y
echo "****      Everything is Nice & Tidy     ****"
echo "**** Exiting SETUP ****"