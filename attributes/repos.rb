default_unless["enable_testing_repos"] = false

case platform_family
when "rhel"
  arch   = kernel['machine']
  major  = platform_version.to_i
  distro = platform?('fedora') ? 'Fedora' : 'RedHat'

  ########################################
  # Yum repos
  ########################################
  default["osops"]["yum_repos"] = {
    "rcb" => {
      "description" => "RCB Ops Stable Repo",
      "uri" => "http://build.monkeypuppetlabs.com/repo/#{distro}/#{major}/#{arch}",
      "enabled" => 1,
      "key" => "RPM-GPG-RCB"
    },
    "epel-openstack" => {
      "description" => "OpenStack Havana Repository for EPEL 6",
      "uri" => "http://repos.fedorapeople.org/repos/openstack/openstack-havana/epel-6",
      "enabled" => 1
    }
  }

  # Testing repositories
  default["osops"]["yum_testing_repos"] = {
    "rcb-testing" => {
      "description" => "RCB Ops Testing Repo",
      "uri" => "http://build.monkeypuppetlabs.com/repo-testing/#{distro}/#{major}/#{arch}",
      "enabled" => 1,
      "key" => "RPM-GPG-RCB"
    }
  }

  # GPG keys
  default["osops"]["yum_keys"] = {
    "RPM-GPG-RCB" => "http://build.monkeypuppetlabs.com/repo/RPM-GPG-RCB.key"
  }

when "debian"
  ########################################
  # Apt repos
  ########################################
  default["osops"]["apt_repos"] = {
    "osops" => {
      "uri" => "http://ppa.launchpad.net/osops-packaging/ppa/ubuntu",
      "distribution" => lsb['codename'],
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "53E8EA35"
    },
    "havana" => {
      "uri" => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
      "distribution" => "precise-updates/havana",
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "EC4926EA"
    }
  }

  # Testing repos
  default["osops"]["apt_testing_repos"] = {
    "havana-proposed" => {
      "uri" => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
      "distribution" => "precise-proposed/havana",
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "EC4926EA"
    },
    # TODO(breu): remove this when the packages go into cloud archive
    "havana-proposed-ppa" => {
      "uri" =>
        "http://ppa.launchpad.net/ubuntu-cloud-archive/havana-staging/ubuntu",
      "distribution" => "precise",
      "components" => ["main"],
      "keyserver" => "hkp://keyserver.ubuntu.com:80",
      "key" => "9F68104E"
    }
  }

end
