#! /bin/bash

## Prepare Server shell script.
## PAOCLOUD COMPANY LIMITED
## Website : www.paocloud.co.th , Email : technical@paocloud.co.th


## General server config ##
sudo hostnamectl set-hostname terraform-lab
sudo timedatectl set-timezone Asia/Bangkok

## User set up ##
sudo useradd pao -s /bin/bash
sudo echo "pao ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
sudo mkdir /home/pao/
sudo mkdir /home/pao/.ssh/
sudo cp /home/ubuntu/.ssh/authorized_keys /home/pao/.ssh/
sudo cp /home/ubuntu/.bashrc /home/pao/
sudo cp /home/ubuntu/.profile /home/pao/
sudo chown -R pao:pao /home/pao/
sudo chmod -R 775 /home/pao/

## Update & Upgrade OS ##
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade

echo "Deployed via Terraform" > /home/pao/.deploy_via_terraform 
