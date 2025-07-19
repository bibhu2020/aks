# Overview
This document talks about how to build a kubernetes opeator using python

# SDK
sudo apt update
sudo apt install python3 python3-pip
sudo pip3 install Kubernetes
sudo pip3 install kopf 
kopf --version
pip3 show kopf

# Debug Operator
kopf run <file>.py --verbose

# Deploy to the cluster
Build a docker and deploy to the cluster

# Kopf Documentation
https://kopf.readthedocs.io/en/stable/install/

