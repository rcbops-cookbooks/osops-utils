#
# Cookbook Name:: osops-utils
# Recipe:: centos-amqplib-keepalive-patch
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
# Install the python-amqplib package early so we can modify it as necessary
#
package "python-amqplib" do
  action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
end

#
# change transport.py in amqplib to use keepalive for sockets
#
template "/usr/lib/python2.6/site-packages/amqplib/client_0_8/transport.py" do
  source "patches/transport.py.python-amqplib-0.6.1-2.el6.noarch.erb"
  owner "root"
  group "root"
  mode "0644"
  only_if {
    ::Chef::Recipe::Patch.check_package_version("python-amqplib", "0.6.1-2.el6", node)
  }
end
