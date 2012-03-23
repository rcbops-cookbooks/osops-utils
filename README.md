Description
===========

Miscellaneous library functions for osops packages.  These include:

 * ip address location


Requirements
============

ipaddr

Attributes
==========

osops_networks is a list of network names and associated CIDR.  These
are used in the get_ip functions.


Usage
=====

node[:osops_networks][:localnet] = 127.0.0.0/8
node[:osops_networks][:management] = 10.0.1.0/24

ip = get_ip_for_net("localnet")  # returns 127.0.0.1
ip = get_ip_for_net("management") # returns the address on management, or error


