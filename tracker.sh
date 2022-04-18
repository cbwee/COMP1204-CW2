#!/bin/bash

#sudo /opt/lampp/lampp restart

/opt/lampp/bin/mysql -u root<<EOF
	CREATE DATABASE IF NOT EXISTS weatherJB;
	#SHOW DATABASES;
	USE weatherJB;
EOF
