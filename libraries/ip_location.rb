#
# Cookbook Name:: osops-utils
# library:: ip_location
#
# Copyright 2012-2013, Rackspace US, Inc.
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

require "chef/search/query"
require "ipaddr"
require "uri"

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

  def rcb_exit_error(msg, options = {})
    log_errors = options.fetch(:log_errors, true)

    if log_errors then
      Chef::Log.error(msg)
    end
    raise msg
  end

  def rcb_safe_deref(hash, path, delim = ".")
    current = hash

    debug("searching for #{path} in #{hash} with delimiter #{delim}")
    path_ary = path.split(delim)
    path_ary.each do |k|
      if current and current.has_key?(k)
        current = current[k]
      elsif current and current.respond_to? k
        current = current.send(k)
      else
        current = nil
      end
    end

    current
  end

  # stub until we can migrate out the IPManagement stuff
  def get_ip_for_net(network, nodeish = nil, options = {})
    _, ip = get_if_ip_for_net(network, nodeish, options)
    return ip
  end

  def get_if_for_net(network, nodeish = nil, options = {})
    iface, _ = get_if_ip_for_net(network, nodeish, options)
    return iface
  end

  def get_if_ip_for_net(network, nodeish = nil, options = {})
    nodeish = node unless nodeish

    return "0.0.0.0" if network == "all"
    return "127.0.0.1" if network == "localhost"

    if !(nodeish.has_key?("osops_networks") and
      nodeish["osops_networks"].has_key?(network)) then

      rcb_exit_error("Can't find network #{network}", options)
    end

    net = IPAddr.new(node["osops_networks"][network])
    nodeish["network"]["interfaces"].each do |interface|
      unless interface[1]['addresses'].nil?
        interface[1]["addresses"].each do |k, v|
          family = v['family']
          prefixlen = v['prefixlen']

          if (family == "inet6" && prefixlen != "128") or (family == "inet" && prefixlen != "32" ) then
            addr=IPAddr.new(k)
            if net.include?(addr) then
              return [interface[0], k]
            end
          end
        end
      end
    end

    rcb_exit_error("Can't find address on network #{network} for node", options)
  end

  def get_config_endpoint(server, service, nodeish=nil, partial=false)
    retval = {}
    nodeish = node unless nodeish
    if svc = rcb_safe_deref(nodeish, "#{server}.services.#{service}")
      retval["network"] = svc["network"]
      retval["path"] = svc["path"] || "/"
      retval["scheme"] = svc["scheme"] || "http"
      retval["port"] = svc["port"] || "80"
      retval["name"] = svc["name"]

      # if we have an endpoint, we'll just parse the pieces
      # Chef-10.12.0 is so broke that node.has_key? does not work
      if svc.keys.include?("uri")
        debug("endpoint URI was provided--overriding default components")
        # if the uri path contains a '%', temporarily sub it out
        # so the uri can be parsed
        uri = URI(svc["uri"].gsub('%', 'xxxxxxxxxx'))
        # sub the '%' back in to pass the path portion into retval
        retval.merge!('path' => uri.path.gsub('xxxxxxxxxx', '%'))
        # pass the other parts into retval
        ["scheme", "port", "host"].each do |x|
          retval.merge!(x => uri.send(x))
        end
      # Chef-10.12.0 is so broke that node.has_key? does not work
      elsif svc.keys.include?("host")
        retval["host"] = svc["host"]
        retval["uri"] =
          "#{retval['scheme']}://#{retval['host']}:#{retval['port']}"
        retval["uri"] += retval["path"]
        debug("endpoint host was provided--created URI as #{retval['uri']}")
      end
    else
      Chef::Log.info("No configured endpoint for #{server}/#{service}")
      retval = nil unless partial
    end
    retval
  end

  def get_bind_endpoint(server, service, nodeish=nil)
    nodeish = node unless nodeish
    retval = get_config_endpoint(server, service, nodeish, true)

    if not retval.empty?
      # we'll get the network from the osops network
      if not retval.include? "host"
        debug("calling IPManagement#get_ip_for_net() for network '#{retval['network']}'")
        retval["host"] =
          Chef::Recipe::IPManagement.get_ip_for_net(
            retval["network"], nodeish)
      end
      if not retval.include? "uri"
        retval["uri"] =
          "#{retval['scheme']}://#{retval['host']}:#{retval['port']}"
        retval["uri"] += retval["path"]
        debug("constructed URI components as: '#{retval['uri']}'")
      end
      retval
    else
      Chef::Log.warn("Cannot find server/service #{server}/#{service}")
      nil
    end
  end

  # Get the access endpoint the mysql master role.
  #
  # This is the same as calling:
  #
  #   get_access_endpoint("mysql-master", "mysql", "db")
  #
  # with the additional override that allowes one to specify a non chef
  # managed mysql server in the following attributes:
  #
  # node["unmanaged"]["mysql"]["host"] = "10.10.10.10"
  # node["unmanaged"]["mysql"]["server_root_password"] = "2d$eo1@eo%r"
  def get_mysql_endpoint( role="mysql-master", server="mysql", service="db", options={} )
    host = node["unmanaged"]["mysql"]["host"] rescue nil

    if not host.nil?
      return {
        "host" => host,
        "name" => server
      }
    end

    get_access_endpoint(role, server, service, options)
  end

  # Get the access endpoint for a role.
  #
  # If a role search returns no results, but the role is in our
  # current runlist, use the bind endpoint from the local node
  # attributes.
  #
  # If a role search returns more than one result, then return
  # the LB config for that service
  #
  # If the role search returns exactly one result, then use
  # the bind endpoint for the service according to that nodes attributes
  #
  def get_access_endpoint(role, server, service, options={})
    path = "#{role}/#{server}/#{service}"
    result = osops_search(
      search_string=role,
      one_or_all=:all,
      include_me=true,
      order=[:role, :recipe],
      safe_deref=nil,
      current_node=nil,
      options
    )

    debug("get_access_endpoint #{path} result: #{result}")

    if result.empty?
      Chef::Log.warn("Cannot find #{server}/#{service} for role #{role}")
      nil
    elsif result.one?
      debug("gap debug: #{result}")
      debug("calling get_bind_endpoint() for #{path} (#{result.first.name})")
      get_bind_endpoint(server, service, result.first)
    else
      debug("calling get_lb_endpoint() for #{path} (#{result.map(&:name)})")
      get_lb_endpoint(role, server, service)
    end
  end

  # return the endpoint info for all roles matching the
  # the service.  This differs from access_endpoint, as it
  # returns all the candidates, not merely the LB vip
  #
  def get_realserver_endpoints(role, server, service, options={})
    result = osops_search(
      search_string=role,
      one_or_all=:all,
      include_me=true,
      order=[:role, :recipe],
      safe_deref=nil,
      current_node=nil,
      options
    )

    debug("calling get_bind_endpoint() for #{result.length} node(s): " +
      result.map(&:name).to_s)

    result.map { |nodeish| get_bind_endpoint(server, service, nodeish) }
  end

  # Get settings for the mysql rol.
  #
  # This is the same as calling:
  #
  #   get_settings_by_role("mysql-master", "mysql")
  #
  # with the additional override that allowes one to specify a non chef
  # managed mysql server in the following attributes:
  #
  # node["unmanaged"]["mysql"]["host"] = "10.10.10.10"
  # node["unmanaged"]["mysql"]["server_root_password"] = "2d$eo1@eo%r"
  def get_mysql_settings(role="mysql-master", settings="mysql", includeme=true, options={})
    host = node["unmanaged"]["mysql"]["host"] rescue nil

    if not host.nil?
      return node["unmanaged"]["mysql"]
    end

    get_settings_by_role(role, settings, includeme, options)
  end

  # Get a specific node hash from another node by role
  #
  # In the event of a search with multiple results,
  # it returns the first match
  #
  # In the event of a search with a no matches, if the role
  # is held on the running node, then the current node hash
  # values will be returned
  #
  # If includeme=false, the current node hash is removed from the results
  # before the results are evaluated and returned
  def get_settings_by_role(role, settings, includeme=true, options={})
    osops_search(
      search_string=role,
      one_or_all=:one,
      include_me=includeme,
      order=[:role],
      safe_deref=settings,
      current_node=nil,
      options
    )
  end

  # Get a specific node hash from another node by recipe
  #
  # In the event of a search with multiple results,
  # it returns the first match
  #
  # In the event of a search with a no matches, if the role
  # is held on the running node, then the current node hash
  # values will be returned
  #
  def get_settings_by_recipe(recipe, settings, options={})
    osops_search(
      search_string=recipe,
      one_or_all=:one,
      include_me=true,
      order=[:recipe],
      safe_deref=settings,
      current_node=nil,
      options
    )
  end

  # Get a specific node hash from another node by tag
  #
  # In the event of a search with multiple results,
  # it returns the first match
  #
  # In the event of a search with a no matches, if the tag
  # is held on the running node, then the current node hash
  # values will be returned
  def get_settings_by_tag(tag, settings, options={})
    osops_search(
      search_string=tag,
      one_or_all=:one,
      include_me=true,
      order=[:tag],
      safe_deref=settings,
      current_node=nil,
      options
    )
  end

  # search for a role and return how many there are in the environment.
  #
  # If includeme=false, the current node is removed from the  search result
  # before the results are evaluated and returned
  def get_role_count(role, includeme=true, options={})
    osops_search(
      search_string=role,
      one_or_all=:all,
      include_me=includeme,
      order=[:role],
      safe_deref=nil,
      current_node=nil,
      options
    ).length
  end

  def get_nodes_by_role(role, includeme=true, options={})
    osops_search(
      search_string=role,
      one_or_all=:all,
      include_me=includeme,
      order=[:role],
      safe_deref=nil,
      current_node=nil,
      options
    )
  end

  def get_nodes_by_recipe(recipe, includeme=true, options={})
    osops_search(
      search_string=recipe,
      one_or_all=:all,
      include_me=includeme,
      order=[:recipe],
      safe_deref=nil,
      current_node=nil,
      options
    )
  end

  def get_nodes_by_tag(tag, includeme=true, options={})
    osops_search(
      search_string=tag,
      one_or_all=:all,
      include_me=includeme,
      order=[:tag],
      safe_deref=nil,
      current_node=nil,
      options
    )
  end

  # Get node hash(es) by recipe or role.
  def osops_search(
    search_string,  # recipe or role name
    one_or_all=:one,# return first node found or a list of nodes?
    #   if set to :all a list will be returned
    #   even if only one node is found.
    include_me=true,# include self in results
    order=[:role, :recipe],   # if only one item is to be returned and
    #   there are results from both the role
    #   search and the recipe search, pick the
    #   first item from the list specified here.%
    #   must be :recipe or :role
    safe_deref=nil, # if nil, return node(s), else return
    #   rcb_safe_deref(node,safe_deref)
    current_node=nil,
    options = {}
  )

    # Next refactor, move options to first/only param
    # Passing options from other methods to override search params
    options = {
      :search_string => search_string,
      :one_or_all => one_or_all,
      :include_me => include_me,
      :order => order,
      :safe_deref => safe_deref,
      :current_node => current_node
    }.merge(options)

    search_string = options[:search_string]
    one_or_all = options[:one_or_all]
    include_me = options[:include_me]
    order = options[:order]
    safe_deref = options[:safe_deref]
    current_node = options[:current_node]

    debug("Osops_search: search_string:#{search_string}, one_or_all:#{one_or_all},"\
      + "include_me:#{include_me}, order:#{order}, safe_deref:#{safe_deref}")
    results = {
      :recipe => [],
      :role => [],
      :tag => []
    }

    current_node ||= node

    for query_type in order
      if include_me and current_node["#{query_type}s"].include? search_string
        debug("node #{current_node} contains #{query_type} #{search_string}, so adding node to results")
        results[query_type] << current_node
        break if one_or_all == :one # skip expensive searches if unnecessary
      end

      search_string.gsub!(/::/, "\\:\\:")
      query = "#{query_type}s:#{search_string} AND chef_environment:#{current_node.chef_environment}"
      debug("osops_search query: #{query}")
      result, _, _ = Chef::Search::Query.new.search(:node, query)
      results[query_type].push(*result)
      break if one_or_all == :one and results.values.map(&:length).reduce(:+).nonzero?
    end #end for

    #combine results into prioritised list
    return_list = order.map { |search_type| results[search_type] }.reduce(:+)

    #remove duplicates
    return_list.uniq!(&:name)

    #remove self if returned by search but include_me is false
    return_list.delete_if { |e| e.name == current_node.name }  if not include_me

    if not safe_deref.nil?
      # result should be dereferenced, do that then remove nils.
      debug("applying deref #{safe_deref}")
      return_list.map! { |nodeish| rcb_safe_deref(nodeish, safe_deref) }
      return_list.delete_if { |item| item.nil? }
    end

    debug("ospos_search return_list: #{return_list}")

    if one_or_all == :one
      #return first item
      return_list.first
    else
      #return list (even if it only contains one item)
      return_list
    end
  end #end function

  def get_lb_endpoint(role, server, service)
    debug("*** GET_LB_ENDPOINT: SERVER[#{server}], SERVICE[#{service}]")

    path = "#{server}.services.#{service}"
    vip_path = "vips.#{server}-#{service}"
    external_vip_path = "external-#{vip_path}"

    if vip = rcb_safe_deref(node, vip_path)
      Chef::Log.info("GET_LB_ENDPOINT: VIP Provided for #{path}")
    elsif vip = rcb_safe_deref(node, external_vip_path)
      Chef::Log.info("GET_LB_ENDPOINT: EXTERNAL VIP Provided for #{path}")
    end

    if vip
      servers = get_realserver_endpoints(role, server, service)
      retval = servers[0]
      if not retval.empty?
        retval["host"] = vip
        retval["uri"] = "#{retval['scheme']}://#{retval['host']}:#{retval['port']}"
        retval["uri"] += retval["path"]
        debug("using vip #{vip} for endpoint (#{retval['uri']})")
        retval
      else
        Chef::Log.warn("Cannot find server/service #{server}/#{service}")
        nil
      end
    else
      # TODO(breu): add more information to this error message to tell the
      # user which vip they need to define in the environment.
      rcb_exit_error "Found more than 1 #{server}/#{service}" +
        " but #{vip_path} is not defined."
    end
  end

  def debug(msg)
    # grab the caller's name (between quotes `') off the top of stack
    method = caller[0][/`([^']*)'/, 1]
    Chef::Log.debug("#{method}(): #{msg}")
  end


end #end module

class Chef::Recipe
  include RCB
end

class Chef::Provider
  include RCB
end

class Chef::Recipe::IPManagement
  extend RCB

  def self.rcb_exit_error(msg, options = {})
    log_errors = options.fetch(:log_errors, true)

    if log_errors then
      Chef::Log.error(msg)
    end
    raise msg
  end

  # find the local ip for a host on a specific network
  def self.get_ip_for_net(network, node, options = {})
    ourname = "#{__method__}():"   # used in debug statements below

    # handle the simple cases
    return "0.0.0.0" if network == "all"
    return "127.0.0.1" if network == "localhost"

    # remap the network if a map is present
    if node.has_key?("osops_networks") and
      node["osops_networks"].has_key?("mapping") and
      node["osops_networks"]["mapping"].has_key?(network) then

      network = node["osops_networks"]["mapping"][network]
    end

    if ! (node.has_key?("osops_networks") and node["osops_networks"].has_key?(network)) then
      rcb_exit_error("Network '#{network}' is not defined (check environment)", options)
    end

    # network number associated with this network
    net = IPAddr.new(node["osops_networks"][network])
    Chef::Log.debug("#{ourname} finding local address for network #{net}")

    # loop thru node's interfaces and look at addresses
    node["network"]["interfaces"].each do |interface|
      Chef::Log.debug("#{ourname} examining interface #{interface[0]}")
      if interface[1].has_key?("addresses") then
        # loop thru each address on this interface
        interface[1]["addresses"].each do |k, v|
          if v["family"] == "inet6" or (v["family"] == "inet" and v["prefixlen"] != "32") then

            addr=IPAddr.new(k)
            if net.include?(addr)
              Chef::Log.debug(ourname + "   ===> using #{addr}")
              return k  # found it
            else
              Chef::Log.debug(ourname + "  - ignoring #{addr}")
            end
          end
        end
      end
    end

    rcb_exit_error("Can't find address on network '#{network}' for node", options)
  end

  # find the realserver ips for a particular role
  def self.get_ips_for_role(role, network, node, options={})
    options = {:order => [:role]}.merge(options)

    self.get_ips_for_search(role, network, node, options)
  end

  # find the realserver ips for a particular recipe
  def self.get_ips_for_recipe(recipe, network, node, options={})
    options = {:order => [:recipe]}.merge(options)

    self.get_ips_for_search(recipe, network, node, options)
  end

  # find the realserver ips for a particular tag
  def self.get_ips_for_tag(tag, network, node, options={})
    options = {:order => [:tag]}.merge(options)

    self.get_ips_for_search(tag, network, node, options)
  end

  # find the realserver ips for a particular role
  def self.get_ips_for_search(term, network, node, options={})
    if Chef::Config[:solo] then
      return [self.get_ip_for_net(network, node)]
    else

      options = {
        :one_or_all => :all,
        :include_me => true,
        :order => [:recipe, :role, :tag],
        :safe_deref => nil,
        :current_node => node
      }.merge(options)

      candidates = osops_search(
        search_string=term,
        one_or_all=options[:one_or_all],
        include_me=options[:include_me],
        order=options[:order],
        safe_deref=options[:safe_deref],
        current_node=options[:current_node],
        options
      ).map { |x| get_ip_for_net(network, x) }

      if candidates == nil or candidates.length <= 0
        error = "Can't find any candidates for search in #{options[:order].join(", ")} for #{term}" +
          " in environment #{node.chef_environment}"

        rcb_exit_error error
      end

      return candidates
    end
  end

  # find the loadbalancer ip for a particular role
  def self.get_access_ip_for_role(role, network, node, options={})
    if Chef::Config[:solo] then
      return self.get_ip_for_net(network, node)
    else
      candidates = osops_search(
        search_string=role,
        one_or_all=:all,
        include_me=true,
        order=[:role],
        safe_deref=nil,
        current_node=node,
        options
      )

      if candidates.one? then
        return get_ip_for_net(network, candidates.first)
      elsif candidates.empty? then
        error = "Can't find any candidates for role #{role}" +
          " in environment #{node.chef_environment}"

        rcb_exit_error error
      else
        if not node["osops_networks"] or not node["osops_networks"]["vips"] or
          not node["osops_networks"]["vips"][role] then

          error = "Can't find lb vip for role '#{role}'" +
            " (osops_networks/vips/#{role})" +
            " in environment, with #{candidates.length} #{role} nodes"

          rcb_exit_error error
        else
          return node["osops_networks"]["vips"][role]
        end
      end
    end
  end
end
