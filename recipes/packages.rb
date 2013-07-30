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
  # If this is a RHEL based system install the RCB prod and testing repos

  major = node['platform_version'].to_i
  arch = node['kernel']['machine']
  server = "http://build.monkeypuppetlabs.com"

  # NOTE(mancdaz): default is to use packages for grizzly from epel
  # If a value is provided for an alternative repo, that repo will get added
  # here. As long as the packages in that repo supercede those in epel, then
  # the openstack packages will get installed from there instead

  yum_repository "epel-openstack-grizzly" do
    repo_name "epel-openstack-grizzly"
    description "OpenStack Grizzly Repository for EPEL 6"
    url node["osops"]["yum_repository"]["openstack"]
    enabled 1
    action :add
    not_if { node["osops"]["yum_repository"]["openstack"].nil? }
  end

  if not platform?("fedora")
    include_recipe "yum::epel"
    yum_os="RedHat"
  else
    yum_os="Fedora"
  end

  yum_key "RPM-GPG-RCB" do
    url "#{server}/repo/RPM-GPG-RCB.key"
    action :add
  end

  yum_repository "rcb" do
    repo_name "rcb"
    description "RCB Ops Stable Repo"
    url "#{server}/repo/#{yum_os}/#{major}/#{arch}"
    key "RPM-GPG-RCB"
    action :add
  end

  yum_repository "rcb-testing" do
    repo_name "rcb-testing"
    description "RCB Ops Testing Repo"
    url "#{server}/repo-testing/#{yum_os}/#{major}/#{arch}"
    key "RPM-GPG-RCB"
    enabled 1
    action :add
  end

when "debian"
  include_recipe "apt"

  apt_repository "osops" do
    uri node["osops"]["apt_repository"]["osops-packages"]
    distribution node["lsb"]["codename"]
    components ["main"]
    keyserver "hkp://keyserver.ubuntu.com:80"
    key "53E8EA35"
    notifies :run, "execute[apt-get update]", :immediately
  end

  apt_repository "grizzly" do
    uri node["osops"]["apt_repository"]["openstack"]
    distribution "precise-updates/grizzly"
    components ["main"]
    keyserver "hkp://keyserver.ubuntu.com:80"
    key "EC4926EA"
    notifies :run, "execute[apt-get update]", :immediately
  end

  if node["developer_mode"] == true
    apt_repository "grizzly-proposed" do
      uri "http://ubuntu-cloud.archive.canonical.com/ubuntu"
      distribution "precise-proposed/grizzly"
      components ["main"]
      keyserver "hkp://keyserver.ubuntu.com:80"
      key "EC4926EA"
      notifies :run, "execute[apt-get update]", :immediately
    end
  else
    apt_repository "grizzly-proposed" do
      action :remove
      notifies :run, "execute[apt-get update]", :immediately
    end
  end

  apt_repository "folsom" do
    action :remove
    notifies :run, "execute[apt-get update]", :immediately
  end

end
