# Threat-Hunting
This repo is dedicated to all my tricks, tweaks and modules for testing and hunting threats. This repo contains multiple directories which are in their own, different modules required for threat hunting. This repo will be updated as and when new changes are made.

# ELK-stack Ansible

This sub-repo is whole dedicated to the installation of ELK-stack using ansible which automates the whole installation process. This repo will be kept updated for whole elkstack inventories.  

The install_elk.sh installs elkstack either as a single-node cluster or it can be used to install multi-node cluster as well. This file is independent of the whole ansible playbook.  

The playbook will also install the required plugins. You need to copy all the files in the ansible folder and execute the fullstack_playbook.yml file. New plugins can be inserted in the vars/main.yml file as variables. The IP Address needs to be changed in the hosts file for multi node cluster installation. Remember to change the heap size in the vars/main.yml else the elastic service will not work due to incorrect memory lock.

SSH disconnection issue has been taken care of by modifying the ansible.cfg file.  

# VirusTotal

This sub-repo contains a python file that queries VirusTotal with all the SHA1 hashes found in the Elasticsearch database and reports back the infection result

# Sysmon-Deployment

This sub-repo contains the deployment of Sysmon via powershell and winrm on multiple sets of machine for analysis. The Sysmon Config file is a modified version from Swift On Security.  
