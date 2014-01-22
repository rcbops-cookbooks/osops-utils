platform_options =  node['osops']['platform']

package recipe_name do
  action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  options platform_options["package_options"]
end
