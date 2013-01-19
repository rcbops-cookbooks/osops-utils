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
node.set_unless['package_component'] = "folsom"

case node["platform"]
when "fedora", "redhat", "centos", "scientific", "amazon"
  # If this is a RHEL based system install the RCB prod and testing repos

  major = node['platform_version'].to_i
  arch = node['kernel']['machine']

  if not platform?("fedora")
    include_recipe "yum::epel"
    yum_os="RedHat"
  else
    yum_os="Fedora"
  end

  if node['package_component'] == "essex-final"
    if platform?("redhat", "fedora", "centos")
      package "yum-priorities" do
        action :install
      end
      template "/etc/yum.repos.d/epel-openstack-essex.repo" do
        source "essex/epel-openstack-essex.repo.erb"
        owner "root"
        group "root"
        mode "0644"
      end
    end
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

  # Stub out the testing repo for OpenStack Folsom packages on el6.  These packages are unsigned
#  if node['package_component'] == "folsom"
#    yum_repository "epel-folsom-testing" do
#      repo_name "epel-folsom-testing"
#      description "EPEL OpenStack Folsom test packages"
#      url "http://repos.fedorapeople.org/repos/openstack/openstack-folsom/epel-6/"
#      enabled 1
#      action :add
#    end
#  end

when "ubuntu","debian"
  include_recipe "apt"

  apt_repository "osops" do
    uri "http://ppa.launchpad.net/osops-packaging/ppa/ubuntu"
    distribution node["lsb"]["codename"]
    components ["main"]
    keyserver "hkp://keyserver.ubuntu.com:80"
    key "53E8EA35"
    notifies :run, resources(:execute => "apt-get update"), :immediately
  end

  apt_repository "folsom" do
      uri "http://ubuntu-cloud.archive.canonical.com/ubuntu"
      distribution "precise-proposed/folsom"
      components ["main"]
      keyserver "hkp://keyserver.ubuntu.com:80"
      key "5EDB1B62EC4926EA"
      #uri "http://ppa.launchpad.net/openstack-ubuntu-testing/folsom-trunk-testing/ubuntu"
      #distribution node["lsb"]["codename"]
      #components ["main"]
      #keyserver "keyserver.ubuntu.com"
      #key "3B6F61A6"
      notifies :run, resources(:execute => "apt-get update"), :immediately
      only_if {node['package_component'] == "folsom"}
  end

end


