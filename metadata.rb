maintainer       "Rackspace Hosting"
maintainer_email "osops@lists.launchpad.net"
license          "Apache 2.0"
description      "Installs/Configures osops-utils"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.15"

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ apt sysctl yum }.each do |dep|
  depends dep
end
