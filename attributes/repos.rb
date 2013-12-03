#
# Cookbook Name:: osops-utils
# Attributes:: repos
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

default_unless["enable_testing_repos"] = false

case platform_family
when "rhel"
  arch   = kernel['machine']
  major  = platform_version.to_i
  prod_distro = platform?('redhat') ? 'RedHat_RHEL-6' : 'CentOS_CentOS-6'
  test_distro = platform?('fedora') ? 'Fedora' : 'RedHat'

  ########################################
  # Yum repos
  ########################################
  default["osops"]["yum_repos"] = {
    "rcb" => {
      "description" => "RCB Ops Stable Repo [DEPRECATED]",
      "uri" => "http://build.monkeypuppetlabs.com/repo/#{test_distro}/#{major}/#{arch}",
      "enabled" => 0,
      "key" => "RPM-GPG-RCB"
    },
    "epel-openstack" => {
      "description" => "OpenStack Havana Repository for EPEL 6",
      "uri" => "http://repos.fedorapeople.org/repos/openstack/openstack-havana/epel-6",
      "enabled" => 1,
      "key" => "RPM-GPG-KEY-RDO-Havana"
    },
    "rpc-extras" => {
      "description" => "RPC OpenStack-Related Packages",
      "uri" => "http://download.opensuse.org/repositories/home:/rpcops:/havana/#{prod_distro}/",
      "enabled" => 1,
      "key" => "RPM-GPG-OBS"
    }
  }

  # Testing repositories
  default["osops"]["yum_testing_repos"] = {
    "rcb-testing" => {
      "description" => "RCB Ops Testing Repo",
      "uri" => "http://build.monkeypuppetlabs.com/repo-testing/#{test_distro}/#{major}/#{arch}",
      "enabled" => 0,
      "key" => "RPM-GPG-RCB"
    }
  }

  # GPG keys
  default["osops"]["yum_keys"] = {
    "RPM-GPG-RCB" => "http://build.monkeypuppetlabs.com/repo/RPM-GPG-RCB.key",
    "RPM-GPG-OBS" => "http://download.opensuse.org/repositories/home:/rpcops/RedHat_RHEL-6/repodata/repomd.xml.key",
    # this seems to be the official location of the RDO Havana key
    "RPM-GPG-KEY-RDO-Havana" => "https://raw.github.com/redhat-openstack/rdo-release/master/RPM-GPG-KEY-RDO-Havana"
  }


when "debian"
  ########################################
  # Apt repos
  ########################################
  default["osops"]["apt_repos"] = {
    "osops" => {
      "uri" => "http://ppa.launchpad.net/osops-packaging/ppa/ubuntu",
      "distribution" => lsb['codename'],
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "53E8EA35"
    },
    "havana" => {
      "uri" => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
      "distribution" => "precise-updates/havana",
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "EC4926EA"
    },
    "rpc-extras" => {
      "uri" => "http://download.opensuse.org/repositories/home:/rpcops:/havana/xUbuntu_12.04/",
      "distribution" => "/",
      "components" => [],
      "key" => "http://download.opensuse.org/repositories/home:/rpcops:/havana//xUbuntu_12.04/Release.key"
    }
  }

  # Testing repos
  default["osops"]["apt_testing_repos"] = {
    "havana-proposed" => {
      "uri" => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
      "distribution" => "precise-proposed/havana",
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "EC4926EA"
    },
    # TODO(breu): remove this when the packages go into cloud archive
    "havana-proposed-ppa" => {
      "uri" =>
        "http://ppa.launchpad.net/ubuntu-cloud-archive/havana-staging/ubuntu",
      "distribution" => "precise",
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "9F68104E"
    }
  }

end
