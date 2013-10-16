#
# Cookbook Name:: osops-utils
# Recipe:: packages
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
#

case node["platform_family"]
when "rhel"
  if not platform?("fedora")
    include_recipe "yum::epel"
  end

  # 'yum_repos' attr is a hash of hashes...
  node["osops"]["yum_repos"].keys.each do |name|
    h = node["osops"]["yum_repos"][name]
    yum_repository name do
      repo_name name
      description h['description']
      url h['uri']
      enabled h['enabled']
      action :add
    end

    # Check if we have a gpg key defined and add it to the resource
    #
    # TODO(brett): In future, may need to conditionally add key attribute to
    # apt_repository resources below. Right now all apt repos have keys.
    if h.has_key?('key')
      yum_r = run_context.resource_collection.find(:yum_repository => name)
      yum_r.key h['key']
    end
  end

  node["osops"]["yum_keys"].keys.each do |name|
    yum_key name do
      url node["osops"]["yum_keys"][name]
      action :add
    end
  end

  if node["enable_testing_repos"] == true
    # nested hashes
    node["osops"]["yum_testing_repos"].keys.each do |name|
      h = node["osops"]["yum_testing_repos"][name]
      yum_repository name do
        repo_name name
        description h['description']
        url h['uri']
        enabled h['enabled']
        action :add
      end
      if h.has_key?('key')
        yum_r = run_context.resource_collection.find(:yum_repository => name)
        yum_r.key h['key']
      end
    end
  else
    # nested hashes
    node["osops"]["yum_testing_repos"].keys.each do |name|
      h = node["osops"]["yum_testing_repos"][name]
      yum_repository name do
        action :remove
      end
    end
  end

when "debian"
  include_recipe "apt"
  # 'apt_repos' attr is a hash of hashes...
  node["osops"]["apt_repos"].keys.each do |name|
    h = node["osops"]["apt_repos"][name]
    apt_repository name do
      uri h['uri']
      distribution h['distribution']
      components h['components']
      keyserver h['keyserver']
      key h['key']
      notifies :run, "execute[apt-get update]", :immediately
    end
  end

  if node["enable_testing_repos"] == true
    # nested hashes
    node["osops"]["apt_testing_repos"].keys.each do |name|
      h = node["osops"]["apt_testing_repos"][name]
      apt_repository name do
        uri h['uri']
        distribution h['distribution']
        components h['components']
        keyserver h['keyserver']
        key h['key']
        notifies :run, "execute[apt-get update]", :immediately
      end
    end
  else
    node["osops"]["apt_testing_repos"].keys.each do |name|
      h = node["osops"]["apt_testing_repos"][name]
      apt_repository name do
        action :remove
        notifies :run, "execute[apt-get update]", :immediately
      end
    end
  end #if node["enable_testing_repos"] == true
end #case node["platform_family"]
