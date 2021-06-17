# Simpli
## v0.0.4 (Geordi La Forge) 
-------------------------------------------

**NOTE**

This project was created in '15/'16 while I worked in Esri Support to quickly stand-up HA deployments for testing as HA Portal for ArcGIS was in its very early stages and no one else was taking the lead on these cases when clients would case in with issues. I took it upon myself to do so and created this for all of Esri Support to leverage as needed. With that said, this project has **NOT** been updated since I have moved on from that role and should not actually be used except for reference possibly as the underlying software is very outdated.


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
