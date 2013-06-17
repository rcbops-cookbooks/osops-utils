#
# Cookbook Name:: osops-utils
# Library:: Chef::Recipe::Patch
#
# Copyright 2009, Rackspace US, Inc.
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

class Chef::Recipe::Patch
  def self.check_package_version(package, version, nodeish = nil)
    nodeish = node unless nodeish
    # TODO(breu): remove nova-apply_patches sometime in the future
    #if !(nodeish["osops"]["apply_patches"] or nodeish["nova"]["apply_patches"])
    if (nodeish["osops"] && nodeish["osops"]["apply_patches"] == false) &&
      (nodeish["nova"] && nodeish["nova"]["apply_patches"] == false)

      Chef::Log.info("osops-utils/patch: package #{package} skipping hotfix" +
        "for #{version} due to node settings")

      return false
    end

    command, pattern = nil

    case nodeish["platform"]
    when "ubuntu", "debian"
      command = "apt-cache policy #{package}"
      pattern = /^\s{2}Installed: (.+)$/
    when "fedora", "centos", "redhat", "scientific", "amazon"
      # TODO(breu): need to test this for fedora
      command = "rpm -q --queryformat '%{VERSION}-%{RELEASE}\n' #{package}"
      pattern = /^([\w.-]+)$/
    end

    if command && pattern
      if _version_installed?(command, pattern, version)
        Chef::Log.info("osops-utils/patch: package #{package} requires a" +
          " hotfix for version #{version}")

        return true
      end
    end

    return false
  end

  def self._version_installed?(command, pattern, version)
    Mixlib::ShellOut.new(command).run_command.stdout.each_line do |line|
      case line
      when pattern
        if $1 == version
          return true
        end
      end
    end

    return false
  end
end
