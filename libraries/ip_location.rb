#!/usr/bin/env ruby

require "chef/search/query"
require "ipaddr"
require "uri"
require "pp"

module RCB
  # These are the new endpoint functions, that return much more information about
  # endpoints.  Sufficient to configure something, I hope.  :/

  # Get the bind information necessary for a service.
  # ex:  IPManagement.get_bind_endpoint("keystone","admin")
  # { "host" => "10.1.0.2",
  #   "port" => 35357,
  #   "scheme" => "http",
  #   "path" => "/v2.0",
  #   "uri" => "http://10.1.0.2:35357/v2.0"
  #   "network" => "management"
  #
  # To define this resource, there must be a service entries like...
  # node["keystone"]["services"]["admin"] =
  # { "network" => "management", "port" => 35357 }
  #
  # IP address is derived from required network, unless overridden
  # Protocol defaults to "http", path defaults to "/".  If a URI
  # is specified, it overrides all other settings, otherwise it is
  # composed from the individual components

  def exit_error(msg)
    Chef::Log.error(msg)
    raise msg
  end

  def safe_deref(hash, path)
    current = hash

    path_ary = path.split(".")
    path_ary.each do |k|
      if current and current.has_key?(k)
        current = current[k]
      else
        current = nil
      end
    end

    current
  end

  def get_bind_endpoint(server, service)
    retval = {}
    if svc = safe_deref(node, "#{server}.services.#{service}")
      retval["path"] = svc["path"] || "/"
      retval["scheme"] = svc["scheme"] || "http"
      retval["port"] = svc["port"] || "80"

      # if we have an endpoint, we'll just parse the pieces
      if svc.has_key?("uri")
        uri = URI(svc["uri"])
        ["path", "scheme", "port", "host"].each do |x|
          retval.merge(x => uri.send(x))
        end
      elsif svc.has_key?("host")
        retval["host"] = svc["host"]
        retval["uri"] = "#{retval['scheme']}://#{retval['host']}:#{retval['port']}"
        retval["uri"] += retval["path"]
      else
        # we'll get the network from the osops network
        retval["host"] = Chef::Recipe::IPManagement.get_ip_for_net(svc["network"], node)
        retval["uri"] = "#{retval['scheme']}://#{retval['host']}:#{retval['port']}"
        retval["uri"] += retval["path"]
      end

      retval
    else
      exit_error("Cannot find server/service #{server}/#{service}")
    end
  end
end

class Chef::Recipe
  include RCB
end

class Chef::Recipe::IPManagement
  # find the local ip for a host on a specific network
  def self.get_ip_for_net(network, node)
    # remap the network if a map is present
    if node.has_key?("osops_networks") and
        node["osops_networks"].has_key?("mapping") and
        node["osops_networks"]["mapping"].has_key?(network)
      network = node["osops_networks"]["mapping"][network]
    end

    if not (node.has_key?("osops_networks") and node["osops_networks"].has_key?(network)) then
      error = "Can't find network #{network}"
      Chef::Log.error(error)
      raise error
    end

    net = IPAddr.new(node["osops_networks"][network])
    node["network"]["interfaces"].each do |interface|
      interface[1]["addresses"].each do |k,v|
        if v["family"] == "inet6" or v["family"] == "inet" then
          addr=IPAddr.new(k)
          if net.include?(addr) then
            return k
          end
        end
      end
    end

    error = "Can't find address on network #{network} for node"
    Chef::Log.error(error)
    raise error
  end

  # find the realserver ips for a particular role
  def self.get_ips_for_role(role, network, node)
    if Chef::Config[:solo] then
      return [self.get_ip_for_net(network, node)]
    else
      candidates, _, _ = Chef::Search::Query.new.search(:node, "chef_environment:#{node.chef_environment} AND roles:#{role}")
      if candidates == nil or candidates.length <= 0
        if node["roles"].include?(role)
          candidates = [node]
        end
      end

      if candidates == nil or candidates.length <= 0
        error = "Can't find any candidates for role #{role} in environment #{node.chef_environment}"
        Chef::Log.error(error)
        raise error
      end

      return candidates.map { |x| get_ip_for_net(network, x) }
    end
  end

  # find the loadbalancer ip for a particular role
  def self.get_access_ip_for_role(role, network, node)
    if Chef::Config[:solo] then
      return self.get_ip_for_net(network, node)
    else
      candidates, _, _ = Chef::Search::Query.new.search(:node, "chef_environment:#{node.chef_environment} AND roles:#{role}")
      if candidates == nil or candidates.length == 0
        if node["roles"].include?(role)
          candidates = [ node ]
        end
      end

      if candidates.length == 1 then
        return get_ip_for_net(network, candidates[0])
      elsif candidates.length == 0 then
        error = "Can't find any candidates for role #{role} in environment #{node.chef_environment}"
        Chef::Log.error(error)
        raise error
      else
        if not node["osops_networks"] or not node["osops_networks"]["vips"] or not node["osops_networks"]["vips"][role] then
          error = "Can't find lb vip for #{role} (osops_networks/vips/#{role}) in environment, with #{candidates.length} #{role} nodes"
          Chef::Log.error(error)
          raise error
        else
          return node["osops_networks"]["vips"][role]
        end
      end
    end
  end
end

