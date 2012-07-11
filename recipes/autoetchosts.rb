#
# Cookbook Name:: autoetchosts
#
# No Copyright.
#
# Based on http://community.opscode.com/cookbooks/autoetchosts
# -*- which was based on...
# Based on http://powdahound.com/2010/07/dynamic-hosts-file-using-chef
# Use at your own risk.
#
 
# Find all nodes, sorting by Chef ID so their
# order doesn't change between runs.
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # not another one
  node.save
  hosts = search(:node, "chef_environment:#{node.chef_environment}")
  
  if hosts.length > 1
    Chef::Log.info("Setting up /etc/hosts for #{hosts.length} entries")
    template "/etc/hosts" do
      source "hosts.erb"
      owner "root"
      group "root"
      mode 0644
      variables(
        :hosts => hosts,
        :fqdn => node[:fqdn],
        :hostname => node[:hostname]
      )
    end
  else
    Chef::Log.info("Skipping /etc/hosts only found #{hosts.length} entries")
  end
end
