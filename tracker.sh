#!/bin/bash

#/opt/lampp/bin/mysql -u root
# Use mysql -u root if the environment is set, or the script is running on Raspberry Pi
mysql -u root<<EOF
	CREATE DATABASE IF NOT EXISTS weatherJB;
	SHOW DATABASES;
	USE weatherJB;
EOF
