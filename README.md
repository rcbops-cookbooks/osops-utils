# Description

Miscellaneous library functions and recipes for OpenStack. This currently includes:

 * ip address location
 * simple /etc/hosts manipulation
 * set up package repositories for various distributions
 * hot patching of package components


## IP Resources

### Requirements

Uses the Ruby libraries `chef/search/query`, `ipaddr` and `uri`


### Attributes

`osops_networks` is a list of network names and associated CIDR. These are used in the `get_ip` functions.
`osops`: `apply_patches` Set to true to apply RCB patches to installed packages.  Default is false.


### Usage

<pre><code>
node['osops_networks']['localnet'] = 127.0.0.0/8
node['osops_networks']['management'] = 10.0.1.0/24
ip = get_ip_for_net("localnet")  # returns 127.0.0.1
ip = get_ip_for_net("management") # returns the address on management, or error
node['osops']['apply_patches'] = true
</code>
</pre>


## autoetchosts

This is included by nova::nova-common


### Usage

include_recipe "osops-utils::autoetchosts"


## Package Resources

This is part of the base role


### Attributes

Package components are added based on the value of node['package_component'] which should be set at the environment level.


### Usage

include_recipe "osops-utils::packages"


## patching

Provide a mechanism for hot patching a file that may be part of a package.  Any changes will most likely be overwritten when the package is updated.



### Usage

Example
<pre>
<code>
template "/usr/share/pyshared/nova/scheduler/filters/affinity_filter.py" do
  source "patches/affinity_filter.py.2012.1+stable~20120612-3ee026e-0ubuntu1.2"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nova-scheduler"), :immediately
  only_if { ::Chef::Recipe::Patch.check_package_version("nova-scheduler","2012.1+stable~20120612-3ee026e-0ubuntu1.2",node) ||
            ::Chef::Recipe::Patch.check_package_version("nova-scheduler","2012.1+stable~20120612-3ee026e-0ubuntu1.3",node) }
end
</code>
</pre>


# License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)

Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)

Author:: Ron Pedde (<ron.pedde@rackspace.com>)

Author:: Joseph Breu (<joseph.breu@rackspace.com>)

Author:: William Kelly (<william.kelly@rackspace.com>)

Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)

Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)

Author:: Matt Ray (<matt@opscode.com>)

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
