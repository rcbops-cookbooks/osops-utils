#
# Cookbook Name:: osops-utils_test
# Recipe:: default
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

require_relative "./support/helpers"

describe_recipe "osops-utils_test::default" do
  include OsopsUtilsTestHelpers

  let(:config) { file(::Dir.glob("/etc/sysctl.d/*rabbitmq.conf").first) }

  it "creates a rabbit sysctl.d config file" do
    config.must_have(:mode, "0644")
    config.must_have(:owner, "root")
    config.must_have(:group, "root")
  end

  it "contains an updated keepalive time" do
    config.must_include("net.ipv4.tcp_keepalive_time = 30")
  end

  it "contains an updated keepalive interval" do
    config.must_include("net.ipv4.tcp_keepalive_intvl = 1")
  end

  it "contains an updated keepalive probes" do
    config.must_include("net.ipv4.tcp_keepalive_probes = 5")
  end
end
