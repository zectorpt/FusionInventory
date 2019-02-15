#!/bin/bash
#Jose Almeida @GFI PT
#2019/02/07

rm -f /tmp/*.ocs
for i in `cat /etc/fusioninventory/esx.lst`; do fusioninventory-esx --user root --password XXXX --host $i --directory /tmp; done >> /var/log/inventesx.log 2>&1
for i in `ls -ahl /tmp/*.ocs |awk '{print $9}'`; do fusioninventory-injector -v --file $i -u http://HOSTNAME/plugins/fusioninventory; done >> /var/log/inventesx.log 2>&1
rm -f /tmp/*.ocs
