#!/bin/bash 
# Simpli, by Michael Hatcher  
# Version: 0.0.4 (Geordi La Forge)

############# 
# VARIABLES # 
############# 

title="Simpli"
fqdn=$(hostname)
local_ip=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/') 
tmp_dir=/tmp/simpli
port='null'

#############
# FUNCTIONS #
#############

function create_tmp_dir
{
   # Create folder if it does not exist
   if [ ! -d "$tmp_dir" ]
   then
        mkdir "$tmp_dir" 2>&1 | tee $LOG
   fi

   # Check that folder is writeable
   if [ ! -w "$tmp_dir" ]
   then
        echo "Temp folder is not writeable."
        echo "Please check that your user id has file modify permissions for /tmp."
        echo "Exiting."
        exit 1;
   fi
}

function extract_resource
{
   tar -zxf resources/core.tar.gz -C /tmp/simpli/
}

function build_deps
{
    echo 'Installing dependencies...' 
    yum -y install openssl-devel pcre-devel gcc > /dev/null; 
    echo '...Done'
    echo
}

function build_resource
{
    echo 'Building Simpli...'
    #navigate to source folder 
    cd $tmp_dir > /dev/null; 
    #compile source  
    make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_CRYPT_H=1 USE_LIBCRYPT=1 > /dev/null; 
    #install haproxy 
    make install > /dev/null; 
    #copy the binaries to needed location 
    cp -R /usr/local/sbin/haproxy /usr/sbin > /dev/null; 
    #copy example config file to new location 
    cp -R examples/haproxy.init /etc/init.d/haproxy > /dev/null; 
    #change file permissions 
    chmod 755 /etc/init.d/haproxy > /dev/null; 
    #create new directory 
    mkdir -p /etc/haproxy > /dev/null; 
    #create empty config file 
    touch /etc/haproxy/haproxy.cfg > /dev/null;  
    echo '...Done'
    echo 
}

function clean_up
{
    rm -rf /tmp/simpli
}

function confirm_info
{
    echo 
    echo '=========================================================' 
    echo '================ IMPORTANT INFORMATION ==================' 
    echo '=========================================================' 
    echo ' Please keep in mind that the standard configuration     '
    echo ' will be using a self-signed certificate and will throw  '
    echo ' errors in your browser. Please use the "Add Certificate '
    echo ' tool" to update the certificate to a signed one after   '
    echo ' your initial configuration.                             '     
    echo '---------------------------------------------------------'
    echo 
    echo ' Do you have the following information?' 
    echo '---------------------------------------------------------'
    echo ' 1. Machine names for all servers to be load balanced?                        '
    echo '---------------------------------------------------------'
    echo
    echo '1) Yes' 
    echo '2) No' 
    read -e -p 'Answer: ' ansr 
    echo 
    if [[ ! $ansr =~ ^[1]$ ]] 
    then 
    echo 'Please gather this information and run script again.' 
        exit 1 
    fi 
    echo  
}

function gather_info
{
    echo '=========================================================' 
    echo ' We are now going to gather your Portal information for  '
    echo ' configuration of Simpli. Please use fully qualified     '
    echo ' machine names.				           '
    echo ' Example: supt000123.esri.com			           ' 
    echo '=========================================================' 
    echo 

    validate_primary
    echo
    validate_backup
    echo
}

function gen_ssl
{
    echo '=========================================================' 
    echo ' We are now going to gather information for generating   '
    echo ' an SSL certificate					   ' 
    echo '=========================================================' 
    echo 
 
    echo "Please choose your Country." 
    read -e -p 'Country: ' country 
    echo "Please choose your State." 
    read -e -p 'State: ' state 
    echo "Please choose your City." 
    read -e -p 'City: ' city 
    echo "Please choose your organization name." 
    read -e -p 'Organization: ' org 
    echo "Please choose your organization department." 
    read -e -p 'Department: ' unit 
    echo 
    openssl req -x509 -subj "/C=$country/ST=$state/L=$city/O=$org/CN=$fqdn" -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/$fqdn.key -out /etc/ssl/$fqdn.crt &> /dev/null;     
    cat /etc/ssl/$fqdn.crt /etc/ssl/$fqdn.key > /etc/ssl/$fqdn.pem
    echo '...Done'
    echo
}

function private_key
{
    openssl genrsa -out /etc/ssl/private.key 4096 &> /dev/null;
}

function build_csr
{
    openssl req -new -sha256 -key /etc/ssl/private.key -out /etc/ssl/$fqdn.csr
}

function view_csr
{
    echo '========================================================='
    echo ' Please copy the below information and save it into a    '
    echo ' file with the .csr extension. This will be the file     '
    echo ' that you provide to your CA for signing.                '
    echo '========================================================='
    echo 
    cat /etc/ssl/$fqdn.csr
    echo
    echo '========================================================='
    echo ' Your CSR can also be found at                   	   '
    echo ' /etc/ssl/'$fqdn'.csr				           '	
    echo '========================================================='
    echo 
    read -p "Press [Enter] to continue."
}

function ca_notes
{
    echo '========================================================='
    echo ' Once you have your CSR signed, please use a file   	   '
    echo ' transfer program like Filezilla to copy the Root,	   '
    echo ' Intermediate and End Entity certificates onto this	   '
    echo ' machine.                                                '               
    echo '                                                         '                  
    echo ' Please ensure that the file extension of the		   '
    echo ' certficates are .cer or it will throw an error and	   '
    echo ' fail.						   '
    echo '========================================================='
    sleep 5
}

function build_cert
{
    echo '========================================================='
    echo ' Did you copy your signed certificates over to the sever '
    echo ' with the correct file extensions? They should be .cer   '
    echo '========================================================='
    echo
    echo '1) Yes'
    echo '2) No'
    read -e -p 'Answer: ' ansr
    if [[ ! $ansr =~ ^[1]$ ]]
    then
    echo 'Please copy them to the server and run script again.'
        exit 1
    fi
    echo
    rm -rf /etc/ssl/$fqdn.pem
    cat /etc/ssl/private.key >> /etc/ssl/$fqdn.pem
    echo 'How many intermediate certificates do you have?'
    read -e -p 'Answer:' certnumber
    echo
    echo 'Path to signed certificate:'
    echo 'Example: /etc/ssl/certificate.cer'
    read -e -p 'Location:' certpath
    echo
    cat $certpath >> /etc/ssl/$fqdn.pem
    i=1
    while [ $i -le $certnumber ]
    do
	echo 'Path to intermediate certificate:'
	echo 'Example: /etc/ssl/intermediate.cer' 	
    	read -e -p 'Location:' interpath
        echo
	cat $interpath >> /etc/ssl/$fqdn.pem
	(( i++ ))
    done
    echo 'Path to root certificate:'
    echo 'Example: /etc/ssl/root.cer'
    read -e -p 'Location:' rootpath
    echo
    cat $rootpath >> /etc/ssl/$fqdn.pem
    echo
    service haproxy restart > /dev/null;
}

function validate_primary
{ 
    echo 'Please enter the name of the Primary Portal machine.' 
    read -e -p 'Primary Portal: ' primary_portal 
    if ping -c 1 $primary_portal &> /dev/null; then 
        primary_result=0 
     else 
        primary_result=1 
    fi 
 
    if [[ "$primary_result" -ne "0" ]]; then         
        echo        
        echo "...Machine name is not valid!"     
        echo   
        validate_primary 
    else 
        echo "...Your primary machine is valid!" 
    fi 
}  

function validate_backup
{ 
    echo 'Please enter the name of the Backup Portal machine.' 
    read -e -p 'Backup Portal: ' backup_portal 
 
    if ping -c 1 $backup_portal &> /dev/null; then 
        backup_result=0 
    else 
        backup_result=1 
    fi 
 
    if [[ "$backup_result" -ne "0" ]]; then             
        echo
        echo "...Machine name is not valid!"
        echo        
        validate_backup 
    else 
        echo "...Your backup machine is valid!" 
    fi 
} 

function web_adap_use
{
    echo 'Are you using a web adaptor in front of Portal?' 
    echo '1) Yes' 
    echo '2) No' 
    read -e -p 'Answer: ' ansr 
    echo 
    if [[ ! $ansr =~ ^[1]$ ]]
    then 
        port=7443
    else     
        port=443
    fi 
    echo   
}

function populate
{
    cat << EOF  >/etc/haproxy/haproxy.cfg 
global 
    log 127.0.0.1   local0 
    daemon 
    maxconn 256 
defaults 
    mode http 
    log     global 
    option  httplog 
    timeout connect 5000ms 
    timeout client 50000ms 
    timeout server 50000ms 
    option forwardfor 
    option http-server-close 
frontend https-in
    bind $local_ip:443 ssl crt /etc/ssl/$fqdn.pem 
    rspadd X-Forwarded-Host:\ 'https:\\\\'$fqdn
    default_backend portal-backend  
backend portal-backend 
    server $primary_portal $primary_portal:$port check ssl verify none 
    server $backup_portal $backup_portal:$port check backup ssl verify none 
listen admin 
    bind *:8443 ssl crt /etc/ssl/$fqdn.pem
    mode http 
    stats refresh 5s 
    stats uri /stats
    stats enable 
EOF
    service haproxy restart > /dev/null;
    echo 
    echo '=========================================================' 
    echo '=========================================================' 
    echo ' You should now be able to navigate to		   '
    echo ' https://'$fqdn':8443/stats                               '  
    echo ' to view the status of the load balancer and portal      '
    echo ' machines.     					   '
    echo '                                                         '                    
    echo ' You should also be able to access your Portal home page '
    echo ' at https://'$fqdn'/arcgis/home.                         '                     
    echo '========================================================='
    sleep 10s

}

function cert
{
    echo '========================================================='
    echo ' Do you wish to start or finish the certificate process?  '
    echo '========================================================='
    echo
    echo '1) Start'
    echo '2) Finish'
    read -e -p 'Answer: ' ansr
    echo
    if [[ ! $ansr =~ ^[2]$ ]]
    then
        private_key
        build_csr
        view_csr
        ca_notes
    else
      	build_cert
    fi
    echo
}

function menu
{
    while :
do
    clear
    cat<<EOF
    ==============================
    Simpli Installer Menu
    ------------------------------
    Please enter your choice:

    (1) Install
    (2) Configure
    (3) Add Certificate
    (Q) Quit
    ------------------------------
EOF
    read -n1 -s -p 'Selection: '
    echo
    case "$REPLY" in
    "1")  echo
          create_tmp_dir
          extract_resource
          build_deps
          build_resource
          clean_up
          echo "Simpli has been installed."
          sleep 5;;
    "2")  echo
          confirm_info
          gather_info
          gen_ssl
          web_adap_use
          populate
          echo "Simpli has been configured."
          sleep 5;;
    "3")  echo
    	  cert
          echo 'Your certificate has been installed.'
    	  sleep 5;;
    "Q")  exit                      ;;
    "q")  exit                      ;; 
     * )  echo "invalid option"     ;;
    esac
    sleep 1
done
}

########
# MAIN #
########

menu
