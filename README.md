#simpli
#version: 0.0.4 (Geordi La Forge) 
-------------------------------------------

Simpli is designed to provide an easy method of setting up a network load balancer. It was
designed to remove almost all administrative functions from the end user and as such, only prompts
a user for a few pieces of information and then handles the rest on its own.

Everthing that the script needs is contained within the resources folder expect a few packages
which are listed below. The script was tested on a number of distributions and every effort
was made to make sure that it will run on any distro that is YUM based.


INSTRUCTIONS 
------------------------------------------- 
1. Run simpli.sh as root

  
LIMITATIONS 
------------------------------------------- 
1. Setup is currently limited to Portal only.
2. Machine validation is dependent on ping.
3. Script has to install openssl-devel, pcre-devel & gcc
4. Limited to YUM based distributions at this time.
