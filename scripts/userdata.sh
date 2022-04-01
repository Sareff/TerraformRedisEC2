#!/bin/sh
sudo yum -y update
sudo yum -y upgrade
cd /opt
sudo mkdir web
cd web
sudo aws s3 cp s3://bucket-task-1-true/ . --recursive
sudo chmod +x web-53
./web-53