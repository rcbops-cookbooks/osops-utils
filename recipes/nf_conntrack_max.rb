#
# Cookbook Name:: base
# Recipe:: nf_conntrack_max
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

nf_conntrack_max = node["osops"]["sysctl"]["nf_conntrack_max"]
if nf_conntrack_max && nf_conntrack_max.is_a?(Integer)
  include_recipe "sysctl::default"
  nf_conntracks = ["net.nf_conntrack_max", "net.netfilter.nf_conntrack_max"]
  nf_conntracks.each do |conntrack|
    sysctl conntrack do
      value nf_conntrack_max
    end
  end
end
