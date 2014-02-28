platform_options =  node['osops']['platform']

package recipe_name do
  action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  options platform_options["package_options"]
end

case node["platform_family"]
when "rhel"
    # TODO(breu): remove this when CentOS packages aren't broken
    # workaround for broken CentOS Packages.
    package "python-six" do
        action :upgrade
    end
end
