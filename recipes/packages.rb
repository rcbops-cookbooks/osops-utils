#
# Cookbook Name:: osops-utils
# Recipe:: yum-rcb
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

# Default to folsom package set
case node["platform"]
when "fedora", "redhat", "centos", "scientific", "amazon"
  # If this is a RHEL based system install the RCB prod and testing repos

  major = node['platform_version'].to_i
  arch = node['kernel']['machine']

  # TODO(breu): remove this repo when we go to GA on the EPEL Grizzly
  # Packages
  yum_repository "epel-openstack-grizzly" do
    repo_name "epel-openstack-grizzly"
    description "OpenStack Grizzly Repository for EPEL 6"
    url "http://repos.fedorapeople.org/repos/openstack/openstack-grizzly/epel-6"
    enabled 1
    action :add
  end

  if not platform?("fedora")
    include_recipe "yum::epel"
    yum_os="RedHat"
  else
    yum_os="Fedora"
  end

  yum_key "RPM-GPG-RCB" do
    url "http://build.monkeypuppetlabs.com/repo/RPM-GPG-RCB.key"
    action :add
  end

  yum_repository "rcb" do
    repo_name "rcb"
    description "RCB Ops Stable Repo"
    url "http://build.monkeypuppetlabs.com/repo/#{yum_os}/#{major}/#{arch}"
    key "RPM-GPG-RCB"
    action :add
  end

  yum_repository "rcb-testing" do
    repo_name "rcb-testing"
    description "RCB Ops Testing Repo"
    url "http://build.monkeypuppetlabs.com/repo-testing/#{yum_os}/#{major}/#{arch}"
    key "RPM-GPG-RCB"
    enabled 1
    action :add
  end

when "ubuntu","debian"
  include_recipe "apt"

  apt_repository "osops" do
    uri node["osops"]["apt_repository"]["osops-packages"]
    distribution node["lsb"]["codename"]
    components ["main"]
    keyserver "hkp://keyserver.ubuntu.com:80"
    key "53E8EA35"
    notifies :run, resources(:execute => "apt-get update"), :immediately
  end

  apt_repository "grizzly" do
      uri node["osops"]["apt_repository"]["openstack"]
      distribution "precise-updates/grizzly"
      components ["main"]
      keyserver "hkp://keyserver.ubuntu.com:80"
      key "EC4926EA"
      notifies :run, resources(:execute => "apt-get update"), :immediately
  end

end


