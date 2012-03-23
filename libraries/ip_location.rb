#!/usr/bin/env ruby

require "ipaddr"

class IpLocation
  # find the local ip for a host on a specific network
  def get_ip_for_net(network, node=@node)
    if not node[:osops_networks][network] then
      Chef::Log.err("Can't find network #{network}")
    end

    net = IPAddr.new(node[:osops_networks][network])
    node[:network][:interfaces].each do |interface|
      interface[:addresses].keys.each do |address|
        addr=IPAddr.new(address)
        if net.include?(addr) then
          return address
        end
      end
    end    
    
    Chef::Log.err("Can't find address on network #{network} for node")
  end

  # find the realserver ips for a particular role
  def get_ips_for_role(role, network)
    if Chef::Config[:solo] then
    else
    end
  end

  # find the loadbalancer ips for a particular role
  def get_access_ips_for_role(role, network)
    if Chef::Config[:solo] then
    else
    end
  end
end
