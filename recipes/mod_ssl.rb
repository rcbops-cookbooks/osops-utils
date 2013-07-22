#
# Cookbook Name:: horizon
# Recipe:: mod_ssl
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

# NOTE (mancdaz): having to copy and edit the mod_ssl recipe from
# the upstream apache2 cookbook as we want to remove it's resource cloning.
# This needs to be removed when the upstream cookbook is fixed
if platform_family?("rhel", "fedora", "suse")

  package "mod_ssl" do
    notifies :run, "execute[generate-module-list]", :immediately
  end

  file "#{node['apache']['dir']}/conf.d/ssl.conf" do
    action :delete
    backup false
  end
end

apache_module "ssl" do
  conf true
end
