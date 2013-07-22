#
# Cookbook Name:: osops-utils_test
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

require_relative "./support/helpers"

describe_recipe "osops-utils_test::packages" do
  include OsopsUtilsTestHelpers

  describe "apt repositories" do
    describe "osops repository" do
      let(:config) { file("/etc/apt/sources.list.d/osops.list") }

      it "creates the osops apt source file" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_exist
        config.must_have(:mode, "0644")
        config.must_have(:owner, "root")
        config.must_have(:group, "root")
      end

      it "contains the url node['osops']['apt_repository']['osops-packages']" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_include(node["osops"]["apt_repository"]["osops-packages"])
      end

      it "contains the dist from node['lsb']['codename']" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_include(" #{node["lsb"]["codename"]} ")
      end

      it "contains the main component" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_match(" main\\Z")
      end

      it "trusts the osops key" do
        skip "Debian family only test" unless node.platform_family?("debian")

        `apt-key export 53E8EA35`.must_include("BEGIN PGP PUBLIC KEY BLOCK")
      end
    end

    describe "grizzly repository" do
      let(:config) { file("/etc/apt/sources.list.d/grizzly.list") }

      it "creates the osops apt source file" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_exist
        config.must_have(:mode, "0644")
        config.must_have(:owner, "root")
        config.must_have(:group, "root")
      end

      it "contains the url from node['osops']['apt_repository']['openstack']" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_include(node["osops"]["apt_repository"]["openstack"])
      end

      it "contains the dist precise-updates/grizzly" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_include(" precise-updates/grizzly ")
      end

      it "contains the main component" do
        skip "Debian family only test" unless node.platform_family?("debian")

        config.must_match(" main\\Z")
      end

      it "trusts the openstack key" do
        skip "Debian family only test" unless node.platform_family?("debian")

        `apt-key export EC4926EA`.must_include("BEGIN PGP PUBLIC KEY BLOCK")
      end
    end
  end

  describe "yum repositories" do
    describe "RCB Yum Key" do
      it "has been downloaded" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        file("/etc/pki/rpm-gpg/RPM-GPG-RCB").must_exist
      end
    end

    describe "grizzly repository" do
      let(:config) { file("/etc/yum.repos.d/epel-openstack-grizzly.repo") }

      it "creates the rcb grizzly yum source file" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        config.must_exist
        config.must_have(:mode, "0644")
        config.must_have(:owner, "root")
        config.must_have(:group, "root")
      end

      it "contains the url" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        url = "http://repos.fedorapeople.org/repos/"
        url += "openstack/openstack-grizzly/epel-6"

        config.must_include("baseurl=#{url}")
      end

      it "contains the repo" do
        skip "Debian family only test" unless node.platform_family?("rhel")

        config.must_include("[epel-openstack-grizzly]")
      end

      it "is enabled" do
        skip "Debian family only test" unless node.platform_family?("rhel")

        config.must_include("enabled=1")
      end
    end

    describe "rcb repository" do
      let(:config) { file("/etc/yum.repos.d/rcb.repo") }

      it "creates the rcb testing yum source file" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        config.must_exist
        config.must_have(:mode, "0644")
        config.must_have(:owner, "root")
        config.must_have(:group, "root")
      end

      it "contains the url from os/major/minor version" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        major = node['platform_version'].to_i
        arch = node['kernel']['machine']
        if node.platform?("fedora")
          yum_os="Fedora"
        else
          yum_os="RedHat"
        end
        version = "#{yum_os}/#{major}/#{arch}"
        url = "http://build.monkeypuppetlabs.com/repo/#{version}"

        config.must_include("baseurl=#{url}")
      end

      it "contains the repo" do
        skip "Debian family only test" unless node.platform_family?("rhel")

        config.must_include("[rcb]")
      end

      it "is enabled" do
        skip "Debian family only test" unless node.platform_family?("rhel")

        config.must_include("enabled=1")
      end

      it "trusts the RCB key" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        config.must_include("gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-RCB")
      end
    end

    describe "rcb testing repository" do
      let(:config) { file("/etc/yum.repos.d/rcb-testing.repo") }

      it "creates the rcb testing yum source file" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        config.must_exist
        config.must_have(:mode, "0644")
        config.must_have(:owner, "root")
        config.must_have(:group, "root")
      end

      it "contains the url from os/major/minor version" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        major = node['platform_version'].to_i
        arch = node['kernel']['machine']
        if node.platform?("fedora")
          yum_os="Fedora"
        else
          yum_os="RedHat"
        end
        version = "#{yum_os}/#{major}/#{arch}"
        url = "http://build.monkeypuppetlabs.com/repo-testing/#{version}"

        config.must_include("baseurl=#{url}")
      end

      it "contains the repo" do
        skip "Debian family only test" unless node.platform_family?("rhel")

        config.must_include("[rcb-testing]")
      end

      it "is enabled" do
        skip "Debian family only test" unless node.platform_family?("rhel")

        config.must_include("enabled=1")
      end

      it "trusts the RCB key" do
        skip "Rhel family only test" unless node.platform_family?("rhel")

        config.must_include("gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-RCB")
      end
    end
  end
end
