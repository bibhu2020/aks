# Install Python
sudo apt update
sudo apt install python3
python3 --version

# Install in Pip in Ubuntu
sudo apt install python3-pip

# Setting Virtual Environment (within a working folder)
$sudo apt install python3-venv 
$sudo python3 -m venv _dev 

# Install Kuberentes Client - Windows
pip install Kubernetes

# Install Kuberentes Client - Ubuntu
pip3 install Kubernetes

# Activate or DeActivate Environment
$source _dev/bin/activate
$deactivate
$rm -rf _dev //delete environment

# Install Required Packages
//$sudo apt install python3-django
$python3 -m pip install django
$python3 -m django --version  
$python3 -m pip install openai

# Getting Started
//$django-admin startproject djangoweb
$django-admin startproject djangoweb
$cd djangoweb
$python3 manage.py startapp chatgpt
$python3 manage.py startapp blog
$python3 manage.py startapp users


# Configure / Migrate Python Admin dB
$python3 manage.py makemigrations #generates the migration scripts  
$python3 manage.py migrate #creates schema and migrates data
$python3 manage.py sqlmigrate <project name> <script generated> #view the sql script generated from makemigrations
e.g. $python3 manage.py sqlmigrate chatgpt 0001_initial.py 
