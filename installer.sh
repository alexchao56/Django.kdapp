#!/bin/bash

echo "Welcome to Django Installer for Koding!"

OUT="/tmp/_Djangoinstaller.out"
mkdir -p $OUT

touch $OUT/"0-Asking for sudo password"
sudo pip install Django

touch $OUT/"100-Django installation completed."