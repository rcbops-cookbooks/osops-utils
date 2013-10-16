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

  if not platform?("fedora")
    include_recipe "yum::epel"
    yum_os="RedHat"
  else
    yum_os="Fedora"
  end

  if node['osops']['rcb']['key'].nil?
    rcb_key = "http://build.monkeypuppetlabs.com/repo/RPM-GPG-RCB.key"
  else
    rcb_key = node['osops']['rcb']['key']
  end

  if node['osops']['rcb']['url'].nil?
    rcb_repo_url = "http://build.monkeypuppetlabs.com/repo/#{yum_os}/#{major}/#{arch}"
  else
    rcb_repo_url = node['osops']['rcb']['url']
  end

  if node['osops']['rcb']['testing-url'].nil?
    rcb_testing_repo_url = "http://build.monkeypuppetlabs.com/repo-testing/#{yum_os}/#{major}/#{arch}"
  else
    rcb_testing_repo_url = node['osops']['rcb']['testing-url']
  end

  # NOTE(mancdaz): default is to use packages for grizzly from epel
  # If a value is provided for an alternative repo, that repo will get added
  # here. As long as the packages in that repo supercede those in epel, then
  # the openstack packages will get installed from there instead

  yum_repository "epel-openstack-havana" do
    repo_name "epel-openstack-havana"
    description "OpenStack Havana Repository for EPEL 6"
    url node["osops"]["yum_repository"]["openstack"]
    enabled 1
    action :add
    not_if { node["osops"]["yum_repository"]["openstack"].nil? }
  end

  yum_key "RPM-GPG-RCB" do
    url rcb_key
    action :add
  end

  yum_repository "rcb" do
    repo_name "rcb"
    description "RCB Ops Stable Repo"
    url rcb_repo_url
    key "RPM-GPG-RCB"
    action :add
  end

  if node["developer_mode"] == true
    yum_repository "rcb-testing" do
      repo_name "rcb-testing"
      description "RCB Ops Testing Repo"
      url rcb_testing_repo_url
      key "RPM-GPG-RCB"
      enabled 1
      action :add
    end
  else
    yum_repository "rcb-testing" do
      action :remove
    end
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

  apt_repository "havana" do
    uri node["osops"]["apt_repository"]["openstack"]
    distribution "precise-updates/havana"
    components ["main"]
    keyserver "hkp://keyserver.ubuntu.com:80"
    key "EC4926EA"
    notifies :run, "execute[apt-get update]", :immediately
  end

  if node["developer_mode"] == true
    apt_repository "havana-proposed" do
      uri "http://ubuntu-cloud.archive.canonical.com/ubuntu"
      distribution "precise-proposed/havana"
      components ["main"]
      keyserver "hkp://keyserver.ubuntu.com:80"
      key "EC4926EA"
      notifies :run, "execute[apt-get update]", :immediately
    end
    # TODO(breu): remove this when the packages go into cloud archive
    apt_repository "havana-proposed-ppa" do
      uri "http://ppa.launchpad.net/ubuntu-cloud-archive/havana-staging/ubuntu"
      distribution "precise"
      components ["main"]
      keyserver "hkp://keyserver.ubuntu.com:80"
      key "9F68104E"
      notifies :run, "execute[apt-get update]", :immediately
    end
  else
    apt_repository "havana-proposed" do
      action :remove
      notifies :run, "execute[apt-get update]", :immediately
    end
    # TODO(breu): remove this when the packages go into cloud archive
    apt_repository "havana-proposed-ppa" do
      action :remove
      notifies :run, "execute[apt-get update]", :immediately
    end
  end
end
