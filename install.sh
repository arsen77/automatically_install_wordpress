#!/bin/bash -e
# runs setup, writes to install log and also emails welcome email with details
datetime=`date "+%d-%m-%Y_%H-%M-%S"`
logfile=install_$datetime.txt
/bin/bash user_setup.sh $1 > $logfile
mail -s 'Install Log Wordpress' you@yourdomain.co.uk < $logfile
