#
# Cookbook Name:: osops-utils
# Attributes:: default
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

default["osops"]["apply_patches"] = false               # cluster_attribute
default["osops"]["do_package_upgrades"] = false         # cluster_attribute
default["osops"]["apt_repository"]["osops-packages"] =
  "http://ppa.launchpad.net/osops-packaging/ppa/ubuntu"
default["osops"]["apt_repository"]["openstack"] =
  "http://ubuntu-cloud.archive.canonical.com/ubuntu"

#  example:   "http://repos.fedorapeople.org/repos/openstack/openstack-grizzly/epel-6"
default["osops"]["yum_repository"]["openstack"] =
  "http://repos.fedorapeople.org/repos/openstack/openstack-grizzly/epel-6"

# platform defaults
case platform_family
when "rhel"
  default["osops"]["platform"] = {
    "common_packages" => ["python-eventlet", "python-ceilometerclient",
      "python-cinderclient", "python-glanceclient", "python-keystoneclient",
      "python-novaclient", "python-quantumclient", "MySQL-python",
      "python-warlock", "curl", "python-keystone"],
    "ssl_common_packages" => ["python-paste-deploy"],
    "package_options" => ""
  }
when "debian"
  default["osops"]["platform"] = {
    "common_packages" => ["python-eventlet", "python-ceilometerclient",
      "python-cinderclient", "python-glanceclient", "python-keystoneclient",
      "python-novaclient", "python-quantumclient", "python-mysqldb",
      "python-warlock", "curl", "python-keystone"],
    "ssl_common_packages" => [],
    "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
