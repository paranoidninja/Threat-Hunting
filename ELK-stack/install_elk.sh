#!/bin/bash
##This script with install ELK-stack 5.x(latest) in Ubuntu 16.04.1
##This file is independent of the ansible playbook
##Author : Paranoid Ninja
##Email : paranoidninja@protonmail.com

set -e

#Global Variables:
#install_xpack=true
install_geoip=true
install_translate=true
install_useragent=true
disable_swap=true
change_heap_size=true
min_heap_size="-Xms4g"	#Change Minumum Heap Size as per requirement
max_heap_size="-Xmx4g"	#Change Maximum Heap Size as per requirement

Elastic() {
	echo -e "`tput setaf 3`\n[+] Installing Elasticsearch...\n`tput setaf 7`"
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
        echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
	apt-get update && apt-get -y install elasticsearch apt-transport-https curl git wget openjdk-8-jre
	service elasticsearch stop

	#Changing Network Hosts
	echo -e "`tput setaf 3`\n[+] Modifying Network Details...\n`tput setaf 7`"
	sed -i "s/\#network.host: 192.168.0.1/network.host: 127.0.0.1/g" /etc/elasticsearch/elasticsearch.yml

	#Disabling Java Swap for Elasticsearch only
	if [ "$disable_swap" = true ]; then
		echo -e "`tput setaf 3`\n[+] Disabling JVM Swap...\n`tput setaf 7`"
		sed -i "s/\#bootstrap.memory_lock: true/bootstrap.memory_lock: true/g" /etc/elasticsearch/elasticsearch.yml
		sed -i "s/\#LimitMEMLOCK=infinity/LimitMEMLOCK=infinity/g" /usr/lib/systemd/system/elasticsearch.service
		sed -i "s/\#MAX_LOCKED_MEMORY=unlimited/MAX_LOCKED_MEMORY=unlimited/g" /etc/default/elasticsearch
		ulimit -l unlimited
		#Updating Services
		echo -e "`tput setaf 3`\n[+] Enabling Services on boot...\n`tput setaf 7`"
		update-rc.d elasticsearch defaults 95 10
		service elasticsearch restart
		sudo /bin/systemctl daemon-reload
		sudo /bin/systemctl enable elasticsearch.service
		echo -e "`tput setaf 3`\n[+] Waiting for Elastic Service to Start...\n`tput setaf 7`"
		sleep 5
		curl http://localhost:9200/_nodes?filter_path=**.mlockall | grep mlockall
	fi;

	#CHanging Heap Size
	if [ "$change_heap_size" = true ]; then
		echo -e "`tput setaf 3`\n[+] Modifying Heap Size to $min_heap_size and $max_heap_size ...\n`tput setaf 7`"
		sed -i "s/-Xms2g/$min_heap_size/g" /etc/elasticsearch/jvm.options
		sed -i "s/-Xmx2g/$max_heap_size/g" /etc/elasticsearch/jvm.options
	fi;

	#Install Xpack
#	if [ "$install_xpack" = true ]; then
#		echo -e "`tput setaf 3`\n[+] Installing Xpack plugin...\n`tput setaf 7`"
#		/usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack
#		echo "xpack.security.enabled: false" >> /etc/elasticsearch/elasticsearch.yml
#	fi;

#INSTALL CURATOR
}

Logstash() {
	echo -e "\n[+] Installing Logstash...\n"
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
	apt-get update && apt-get -y install screen logstash apt-transport-https curl git wget openjdk-8-jre
	mkdir /usr/share/logstash/config
	cp -r /etc/logstash/* /usr/share/logstash/config/

	#Installing PLugins
#	if [ "$install_xpack" = true ]; then
#		echo -e "`tput setaf 3`\n[+] Installing Xpack plugin...\n`tput setaf 7`"
#		/usr/share/logstash/bin/logstash-plugin install x-pack
#	fi;
	if [ "$install_geoip" = true ]; then
		echo -e "`tput setaf 3`\n[+] Installing Geoip plugin...\n`tput setaf 7`"
		/usr/share/logstash/bin/logstash-plugin install logstash-filter-geoip
	fi;
	if [ "$install_translate" = true ]; then
		echo -e "`tput setaf 3`\n[+] Installing Translate plugin...\n`tput setaf 7`"
		/usr/share/logstash/bin/logstash-plugin install logstash-filter-translate
	fi;
	if [ "$install_useragent" = true ]; then
		echo -e "`tput setaf 3`\n[+] Installing Translate plugin...\n`tput setaf 7`"
		/usr/share/logstash/bin/logstash-plugin install logstash-filter-useragent
	fi;
}

Kibana() {
	echo -e "`tput setaf 3`\n[+] Installing Kibana...\n`tput setaf 7`"
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
	apt-get update && apt-get install -y kibana apt-transport-https curl git wget openjdk-8-jre

	#Changing Network Hosts
	echo -e "`tput setaf 3`\n[+] Modifying Network Details...\n`tput setaf 7`"
	sed -i 's/\#server.host: "localhost"/server.host: 0.0.0.0/g' /etc/kibana/kibana.yml

	#ADD KIBANA ELASTICSEARCH IP YAML FILE MODIFICATION

	#Updating Services
	echo -e "`tput setaf 3`\n[+] Enabling Services on boot...\n`tput setaf 7`"
	update-rc.d kibana defaults 95 10
	/bin/systemctl daemon-reload
	/bin/systemctl enable kibana.service
	service kibana restart

#	if [ "$install_xpack" = true ]; then
#		echo -e "`tput setaf 3`\n[+] Installing Xpack plugin...\n`tput setaf 7`"
#		/usr/share/kibana/bin/kibana-plugin install x-pack
#		echo "xpack.security.enabled: false" >> /etc/elasticsearch/elasticsearch.yml
#	fi;
}

Help() {
	echo -e "\n`tput setaf 3`[-]Help: Please specify command line parameters:\n-e\tInstall Elasticsearch\n-l\tInstall Logstash\n-k\tInstall Kibana\n-elk\t Install Full Elkstack\n[-] eg:- `tput setaf 2`$0 -e\n`tput setaf 7`"
}

#Check root access
if [[ $UID != 0 ]]; then
	echo -e "\n`tput setaf 1`Your derp level is too high, I don't like you..!`tput setaf 7`\n"
else
	if [ -z "$1" ]; then
		Help
	elif [[ $1 == '-e' ]]; then
		Elastic
	elif [[ $1 == '-k' ]]; then
		Kibana
	elif [[ $1 == '-l' ]]; then
		Logstash
	elif [[ $1 == '-elk' ]]; then
		Elastic
		Logstash
		Kibana
	else
		Help
	fi;
fi;

set +e
