#!/bin/bash

if [ ! -x "/usr/bin/launch_rake" ] ; 
then
	echo "setup rakefile launcher"
	sudo cp launch_rake /usr/bin
	sudo chmod 755 /usr/bin/launch_rake
fi

PORT=$1
PWD=`pwd`
cat $PWD/startup.tmpl | sed -e s:#PWD#:$PWD: | sed -e s/#PORT#/$PORT/ >> ~/.bash_profile


