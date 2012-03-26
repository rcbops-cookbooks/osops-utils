#!/usr/bin/env ruby

require "chef/search/query"
require "ipaddr"
require "pp"

class Chef::Recipe::IPManagement
  # find the local ip for a host on a specific network
  def self.get_ip_for_net(network, node)
    if not node[:osops_networks][network] then
      Chef::Log.err("Can't find network #{network}")
    end

    net = IPAddr.new(node[:osops_networks][network])
    node[:network][:interfaces].each do |interface|
      pp interface
      interface[1][:addresses].each do |k,v|
        if v[:family] == "inet6" or v[:family] == "inet" then
          addr=IPAddr.new(k)
          if net.include?(addr) then
            return k
          end
        end
      end
    end    
    
    Chef::Log.err("Can't find address on network #{network} for node")
  end

  # find the realserver ips for a particular role
  def self.get_ips_for_role(role, network, node)
    if Chef::Config[:solo] then
      return node[:controller_ipaddress]
    else
      candidates, something, result_count = Chef::Search::Query.new.search(:node, "chef_environment:#{node.chef_environment} AND role:#{role}")

      if result_count == 0 then
        Chef::Log.err("Can't find any candidates for roled #{role} in environment #{node.chef_environment}")
      end

      return candidates.map { |x| get_ip_for_net(network, x) }
    end
  end

  # find the loadbalancer ip for a particular role
  def self.get_access_ips_for_role(role, network, node)
    if Chef::Config[:solo] then
      return node[:controller_ipaddress]
    else
      candidates, something, result_count = Chef::Search::Query.new.search(:node, "chef_environment:#{node.chef_environment} AND role:#{role}")
      if result_count == 1 then
        return get_ip_for_net(network, candidates[0], node)
      else
        return node[:osops_vips][role]
      end
    end
  end
end

