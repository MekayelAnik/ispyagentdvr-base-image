#!/bin/bash

# Exit on error and print each command for debugging
set -ex

echo "****		Removing Residue Files, Folders. Cleaning up the Image		****"
apt-get purge gnupg2 rsync -y --autoremove --allow-remove-essential
rm -vrf /etc/apt/sources.list.d/jellyfin.sources /etc/apt/sources.list.d/sid.sources /etc/apt/sources.list.d/backports.sources /var/lib/apt/lists/* 
rm -vrf /var/lib/apt/lists/*
apt-get clean autoclean -y
apt-get autoremove -y
echo "****      Everything is Nice & Tidy     ****"
echo "**** Exiting SETUP ****"