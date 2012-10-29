#
# Cookbook Name:: osops-utils
# Recipe:: autonovaknownhosts
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'fileutils'

# nova resize action uses ssh as the nova user to do prep on the new target
# this breaks if strict host key checking is enabled and the host key
# is not in $HOME/.ssh/known_hosts. 
#
# this pulls host keys for all nodes, adding them to $HOME/.ssh/known_hosts as needed

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  nodes = search(:node, "chef_environment:#{node.chef_environment}")

  Chef::Log.info("osops-utils/autonovaknownhosts: Compiling list of host DSA keys")

  FileUtils.mkdir_p("/var/lib/nova/.ssh/")

  known_hosts = []
  if File.exist?("/var/lib/nova/.ssh/known_hosts")
    known_hosts = File.readlines("/var/lib/nova/.ssh/known_hosts")
  end

  nodes.each do |node|
    host_line = "#{node["fqdn"]},#{node["ipaddress"]} ssh-dss #{node["keys"]["ssh"]["host_dsa_public"]}\n"
    unless known_hosts.include?(host_line)
      Chef::Log.info("osops-utils/autonovaknownhosts: Adding host DSA key for #{node["fqdn"]}")
      known_hosts << host_line
    end
  end

  Chef::Log.info("osops-utils/autonovaknownhosts: Writing /var/lib/nova/.ssh/known_hosts")
  File.open("/var/lib/nova/.ssh/known_hosts", File::WRONLY|File::CREAT, 0644) do |f|
    f.write(known_hosts.join)
  end
end
