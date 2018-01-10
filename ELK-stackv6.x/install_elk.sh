#!/bin/bash
##This script with install ELK-stack 6.x(latest) in Ubuntu 16.04.1
##This file is independent of the ansible playbook
##Author : Paranoid Ninja
##Email : paranoidninja@protonmail.com

set -e

#Global Variables:
disable_swap=true
change_heap_size=true
min_heap_size="-Xms2g"	#Change Minumum Heap Size as per requirement
max_heap_size="-Xmx2g"	#Change Maximum Heap Size as per requirement
EIP="192.168.1.10"

Elastic() {
	rm -rf /etc/apt/sources.list.d/elastic-*
	echo -e "`tput setaf 3`\n[+] Installing Elasticsearch...\n`tput setaf 7`"
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
	apt-get update && apt-get -y install elasticsearch apt-transport-https curl git wget openjdk-8-jre
	service elasticsearch stop

	#Changing Network Hosts
	echo -e "`tput setaf 3`\n[+] Modifying Network Details...\n`tput setaf 7`"
	echo "" > /etc/elasticsearch/elasticsearch.yml
	echo "cluster.name: ThreatHunting" >> /etc/elasticsearch/elasticsearch.yml
	echo "node.name: ATH-1" >> /etc/elasticsearch/elasticsearch.yml
	echo "path.data: /var/lib/elasticsearch" >> /etc/elasticsearch/elasticsearch.yml
	echo "path.logs: /var/log/elasticsearch" >> /etc/elasticsearch/elasticsearch.yml
	echo "http.host: $EIP" >> /etc/elasticsearch/elasticsearch.yml
	echo "network.host: $EIP" >> /etc/elasticsearch/elasticsearch.yml
	echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml

	#Disabling Java Swap for Elasticsearch only
	if [ "$disable_swap" = true ]; then
		#Updating Services
		echo -e "`tput setaf 3`\n[+] Enabling Services on boot...\n`tput setaf 7`"
		update-rc.d elasticsearch defaults 95 10
		service elasticsearch stop
		sudo /bin/systemctl daemon-reload
		sudo /bin/systemctl enable elasticsearch.service
		echo -e "`tput setaf 3`\n[+] Disabling JVM Swap...\n`tput setaf 7`"
        	echo "bootstrap.memory_lock: true" >> /etc/elasticsearch/elasticsearch.yml
        	echo -e "[Service]\nLimitMEMLOCK=infinity" >> /etc/systemd/system/elasticsearch.service.d/override.conf
        	echo "MAX_LOCKED_MEMORY=unlimited" >> /etc/default/elasticsearch
        	ulimit -l unlimited
		sudo /bin/systemctl daemon-reload
		echo -e "`tput setaf 3`\n[+] Waiting for Elastic Service to Start...\n`tput setaf 7`"
		sleep 5
		curl http://$EIP:9200/_nodes?filter_path=**.mlockall | grep mlockall
	fi;

	#Changing Heap Size
	if [ "$change_heap_size" = true ]; then
		echo -e "`tput setaf 3`\n[+] Modifying Heap Size to $min_heap_size and $max_heap_size ...\n`tput setaf 7`"
		sed -i "s/-Xms2g/$min_heap_size/g" /etc/elasticsearch/jvm.options
		sed -i "s/-Xmx2g/$max_heap_size/g" /etc/elasticsearch/jvm.options
	fi;
}

Logstash() {
	echo -e "\n[+] Installing Logstash...\n"
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
	apt-get update && apt-get -y install screen logstash apt-transport-https curl git wget openjdk-8-jre
}

Kibana() {
	echo -e "`tput setaf 3`\n[+] Installing Kibana...\n`tput setaf 7`"
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
	apt-get update && apt-get install -y kibana apt-transport-https curl git wget openjdk-8-jre

	#Changing Network Hosts
	echo -e "`tput setaf 3`\n[+] Modifying Network Details...\n`tput setaf 7`"
	sed -i 's/\#server.host: "localhost"/server.host: 0.0.0.0/g' /etc/kibana/kibana.yml

	#Updating Services
	echo -e "`tput setaf 3`\n[+] Enabling Services on boot...\n`tput setaf 7`"
	update-rc.d kibana defaults 95 10
	/bin/systemctl daemon-reload
	/bin/systemctl enable kibana.service
	service kibana restart
}

Help() {
	echo -e "\n`tput setaf 3`[-] Help: Please specify command line parameters:\n-e\tInstall Elasticsearch\n-l\tInstall Logstash\n-k\tInstall Kibana\n-elk\t Install Full Elkstack\n[-] eg:- `tput setaf 2`$0 -e\n`tput setaf 3`[!] Also, don't forget to modify the Elastic IP as EIP in script`tput setaf 7`"
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
