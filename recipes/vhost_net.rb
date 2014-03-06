#
# Cookbook Name:: base
# Recipe:: vhost_net
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

vhost_net = "vhost_net"

case node["platform"]
  when "ubuntu", "debian"
    execute "module_persist" do
      command "echo #{vhost_net} | tee -a /etc/modules"
      not_if "grep -w ^#{vhost_net} /etc/modules"
      only_if "modinfo #{vhost_net}"
      notifies :run, "execute[load_module]", :delayed
    end
  when "centos", "redhat", "amazon", "scientific"
    rhel_module = "/etc/sysconfig/modules/#{vhost_net}.modules"
    execute "module_persist" do
      command <<-EOH
      cat > #{rhel_module} <<EOF
      #!/usr/bin/env bash
      /sbin/insmod #{vhost_net}
      EOF

      chmod +x #{rhel_module}
      EOH
      not_if "grep -w ^#{vhost_net} #{rhel_module}"
      only_if "modinfo #{vhost_net}"
      notifies :run, "execute[load_module]", :delayed
    end
end

execute "load_module" do
  command "/sbin/modprobe #{vhost_net}"
  action :nothing
end
