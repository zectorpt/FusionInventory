#!/bin/bash
#Jose Almeida @GFI PT
#2019/02/07

echo "Generating computer.csv"
rm -f /home/snow/computer.csv
mysql -u glpi -p'XXXX' glpi << EOF
select
        glpi_computers.name hostname,
        if (substr(glpi_computers.serial,1,6)='VMware','Y','N') isvirtual,
        glpi_computers.uuid uuid,
        "" location,
        glpi_operatingsystems.name os,
        glpi_operatingsystemversions.name osversion,
        tip.list_ip,
        tram.total_ram ram,
        tcpu.total_cpucorecount cpucorecount,
        tcpu.designation cputype,
        tdisk.total_provisionedstorage,
        tdisk.total_usedstorage,
        "" deploydate,
        "" environment,
        "" sign,
        glpi_plugin_fusioninventory_agents.last_contact lastinventory,
        "" vlan,
        "" managedby
INTO OUTFILE '/home/snow/computer.csv' FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n'
from
        glpi_computers
        inner join glpi_items_operatingsystems on glpi_computers.id = glpi_items_operatingsystems.items_id
        inner join glpi_operatingsystems on glpi_items_operatingsystems.operatingsystems_id = glpi_operatingsystems.id
        inner join glpi_operatingsystemversions on glpi_items_operatingsystems.operatingsystemversions_id = glpi_operatingsystemversions.id
        left join (select glpi_computers.id c_id, sum(glpi_items_devicememories.size) total_ram from glpi_computers left join glpi_items_devicememories on glpi_items_devicememories.items_id = glpi_computers.id group by glpi_computers.name) tram on tram.c_id = glpi_computers.id
        left join (select glpi_computers.id c_id, sum(glpi_items_deviceprocessors.nbcores) total_cpucorecount,  glpi_deviceprocessors.designation designation from glpi_computers inner join glpi_items_deviceprocessors on glpi_items_deviceprocessors.items_id = glpi_computers.id inner join glpi_deviceprocessors on glpi_deviceprocessors.id = glpi_items_deviceprocessors.deviceprocessors_id group by glpi_computers.name) tcpu on tcpu.c_id = glpi_computers.id
        left join (select glpi_computers.id c_id, sum(glpi_computerdisks.totalsize) total_provisionedstorage, sum(glpi_computerdisks.totalsize) - sum(glpi_computerdisks.freesize) total_usedstorage from glpi_computers left join glpi_computerdisks on glpi_computerdisks.computers_id = glpi_computers.id left join glpi_filesystems on glpi_computerdisks.filesystems_id = glpi_filesystems.id where glpi_filesystems.name in ('ext','ext2','ext3','ext4','FAT','FAT32','XFS','vmfs') group by glpi_computers.name) tdisk on tdisk.c_id = glpi_computers.id
        left join (select glpi_computers.id c_id, group_concat(glpi_ipaddresses.name separator ',') list_ip from glpi_computers left join glpi_networkports on glpi_networkports.items_id = glpi_computers.id  left join glpi_ipaddresses on glpi_ipaddresses.items_id = glpi_networkports.id where glpi_ipaddresses.version <> 0 group by glpi_computers.name) tip on tip.c_id = glpi_computers.id
        left join glpi_plugin_fusioninventory_agents on glpi_plugin_fusioninventory_agents.computers_id = glpi_computers.id
group by glpi_computers.name
order by glpi_computers.name;
EOF
echo "SED computer.csv"

sed -i "1i\hostname;isvirtual;serial;location;os;osversion;ip;ram;cpucorecount;cputype;provisionedstorage;usedstorage;deploydate;environment;sign;lastinventory;vlan;managedby" /home/snow/computer.csv

#----------------
echo "Generating installedpackages.csv"
rm -f /home/snow/installedpackages.csv && echo "SELECT DISTINCT glpi_computers.name,glpi_softwares.name,glpi_softwareversions.name INTO OUTFILE '/home/snow/installedpackages.csv' FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' FROM glpi_computers INNER JOIN glpi_computers_softwareversions on glpi_computers_softwareversions.computers_id = glpi_computers.id LEFT JOIN glpi_softwares on glpi_softwares.id = glpi_computers_softwareversions.softwareversions_id LEFT JOIN glpi_softwareversions on glpi_softwareversions.softwares_id = glpi_softwares.id;" | mysql -u glpi -p'XXXX' glpi --skip-column-names

echo "SED installedpackages.csv"
sed -i "1i\hostname;installedpackages;version" /home/snow/installedpackages.csv

#---------------
echo "Generating ipaddress.csv"
rm -f /home/snow/ipaddress.csv && echo "SELECT glpi_computers.name,glpi_networkports.name,glpi_ipaddresses.name,glpi_ipnetworks.netmask,glpi_ipnetworks.gateway,glpi_networkports.mac INTO OUTFILE '/home/snow/ipaddress.csv' FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' FROM glpi_computers LEFT JOIN glpi_networkports on glpi_networkports.items_id = glpi_computers.id INNER JOIN glpi_ipaddresses on glpi_ipaddresses.items_id = glpi_networkports.id LEFT JOIN glpi_ipaddresses_ipnetworks on glpi_ipaddresses_ipnetworks.ipaddresses_id = glpi_ipaddresses.id LEFT JOIN glpi_ipnetworks on glpi_ipnetworks.id = glpi_ipaddresses_ipnetworks.ipnetworks_id WHERE glpi_ipaddresses.version <> 0;" | mysql -u glpi -p'XXXX' glpi --skip-column-names

echo "SED ipaddress.csv"
sed -i "1i\computer_name;networkcard;ipaddress;range;gateway;mac" /home/snow/ipaddress.csv
sed -i '/::/d' /home/snow/ipaddress.csv

#---------------
echo "Generating filesystem.csv"
rm -f /home/snow/filesystem.csv && echo "SELECT glpi_computers.name,glpi_filesystems.name,glpi_computerdisks.device,glpi_computerdisks.mountpoint,glpi_computerdisks.totalsize,glpi_computerdisks.freesize INTO OUTFILE '/home/snow/filesystem.csv' FIELDS TERMINATED BY ';' LINES TERMINATED BY '\n' FROM glpi_computers LEFT JOIN glpi_computerdisks on glpi_computerdisks.computers_id = glpi_computers.id LEFT JOIN glpi_filesystems on glpi_computerdisks.filesystems_id = glpi_filesystems.id;" | mysql -u glpi -p'XXXX' glpi --skip-column-names

echo "SED filesystem.csv"
sed -i "1i\computer_name;fs_name;device;mountpoint;totalsize;freesize" /home/snow/filesystem.csv

sed -i "s/;\\\N/;/g" /home/snow/*.csv

#--------------
echo "Files can be found in vl068379 --> /home/snow/"

exit 0
