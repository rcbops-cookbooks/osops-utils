Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[osops-utils]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========

Miscellaneous library functions and recipes for OpenStack. This currently includes:

* ip address location
* simple /etc/hosts manipulation
* set up package repositories for various distributions
* hot patching of package components


Requirements
============

Chef 11.0 or higher required (for Chef environment use).

Platforms
---------

This cookbook is actively tested on the following platforms/versions:

* Ubuntu-12.04
* CentOS-6.3

While not actively tested, this cookbook should also work the following platforms:

* Debian/Mint derivitives
* Amazon/Oracle/Scientific/RHEL

Cookbooks
---------

The following cookbooks are dependencies:

* apt
* sysctl
* yum


Recipes
=======

default
-------
Installs rabbitmq related tcp settings in sysctl

packages
--------
Installs various apt/yum repos

autoetchosts
------------
Installs host file entries for all nodes in current chef environment


Libraries
=========

ip_location
-----------

### Requirements

Uses the Ruby libraries `chef/search/query`, `ipaddr` and `uri`


### Attributes

`osops_networks` is a list of network names and associated CIDR. These are used in the `get_ip` functions.
`osops`: `apply_patches` Set to true to apply RCB patches to installed packages.  Default is false.
`osops`: `do_package_upgrades` Set to true to upgrade certain packages during a chef run.  Default is false.


### Usage

```ruby
node['osops_networks']['localnet'] = 127.0.0.0/8
node['osops_networks']['management'] = 10.0.1.0/24
ip = get_ip_for_net("localnet")  # returns 127.0.0.1
ip = get_ip_for_net("management") # returns the address on management, or error
node['osops']['apply_patches'] = true
```


autoetchosts
------------

This is included by nova::nova-common


### Usage

```ruby
include_recipe "osops-utils::autoetchosts"
```


patching
--------

Provide a mechanism for hot patching a file that may be part of a package.  Any changes will most likely be overwritten when the package is updated.

### Usage

```ruby
template "/usr/share/pyshared/nova/scheduler/filters/affinity_filter.py" do
  source "patches/affinity_filter.py.2012.1+stable~20120612-3ee026e-0ubuntu1.2"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nova-scheduler"), :immediately
  only_if { ::Chef::Recipe::Patch.check_package_version("nova-scheduler","2012.1+stable~20120612-3ee026e-0ubuntu1.2",node) ||
            ::Chef::Recipe::Patch.check_package_version("nova-scheduler","2012.1+stable~20120612-3ee026e-0ubuntu1.3",node) }
end
```


Attributes
==========
* `default["osops"]["apply_patches"]` - Enable/disable the application of patches
* `default["osops"]["do_package_upgrades"]` - Enable/disable automatic package upgrades
* `default["osops"]["apt_repository"]["osops-packages"]` - Url of the osops packages repository
* `default["osops"]["apt_repository"]["openstack"]` - Url of the openstack packages repository

Templates
=========
* `essex/epel-openstack-essex.repo.erb` - OpenStack Essex Repo template for rhel

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Chris Laco (<chris.laco@rackspace.com>)  
Author:: Matt Ray (<matt@opscode.com>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)  

Copyright 2012 Rackspace US, Inc.

Copyright 2012 Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
