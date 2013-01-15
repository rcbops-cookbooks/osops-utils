#
# Cookbook Name:: osops-utils
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

# set some nice tcp timeouts for rabbitmq reconnects
include_recipe "sysctl::default"
sysctl_multi "rabbitmq" do
      instructions("net.ipv4.tcp_keepalive_time" => "30",
                   "net.ipv4.tcp_keepalive_intvl" => "1",
                   "net.ipv4.tcp_keepalive_probes" => "5")
end
