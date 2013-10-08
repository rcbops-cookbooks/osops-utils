name             "osops-utils"
maintainer       "Rackspace US, Inc"
license          "Apache 2.0"
description      "Installs and configures osops-utils."
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version           "4.2.0"

%w{ amazon centos debian fedora oracle redhat scientific ubuntu }.each do |os|
  supports os
end

%w{ apt sysctl yum }.each do |dep|
  depends dep
end

recipe "osops-utils::default",
  "Installs rabbitmq related tcp settings in sysctl"

recipe "osops-utils::packages",
  "Installs various apt/yum repos"

recipe "osops-utils::autoetchosts",
  "Installs host file entries for all nodes in current chef environment"

attribute "osops/apply_patches",
  :description => "Enable/disable the application of patches",
  :default => "false"

attribute "osops/do_package_upgrades",
  :description => "Enable/disable automatic package upgrades",
  :default => "false"

attribute "apt_repository/osops-packages",
  :description => "Url of the osops packages repository"

attribute "apt_repository/openstack",
  :description => "Url of the openstack packages repository"
