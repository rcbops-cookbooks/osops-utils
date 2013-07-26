#
# Cookbook Name:: osops-utils
# Recipe:: openrc 
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

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
# DE153 replacing public endpoint default for openrc with internal endpoint
ks_internal_endpoint = get_access_endpoint(ks_api_role, ks_ns, "internal-api")
# Get settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")
# Get credential settings from role[keystone-setup]
ec2_creds = get_settings_by_role("keystone-setup", "credentials")
# Search for nova ec2 api endpoint info
ec2_public_endpoint = get_access_endpoint("nova-api-ec2", "nova", "ec2-public")

# TODO: need to re-evaluate this for accuracy
template "/root/openrc" do
  source "openrc.erb"
  owner "root"
  group "root"
  mode "0600"
  vars = {
    "user" => keystone["admin_user"],
    "tenant" => keystone["users"][keystone["admin_user"]]["default_tenant"],
    "password" => keystone["users"][keystone["admin_user"]]["password"],
    "keystone_auth_uri" => ks_internal_endpoint["uri"],
    "nova_api_version" => "1.1",
    "keystone_region" => node["nova"]["compute"]["region"],
    "auth_strategy" => "keystone",
    "ec2_url" => ec2_public_endpoint["uri"],
    "ec2_access_key" => ec2_creds["EC2"][keystone['admin_user']]["access"],
    "ec2_secret_key" => ec2_creds["EC2"][keystone['admin_user']]["secret"]
  }
  variables(vars)
end

# NOTE(shep): this is for backwards compatability with Alamo
link "/root/.novarc" do
  to "/root/openrc"
  link_type :symbolic
  only_if { File.exists? "/root/openrc" }
end
