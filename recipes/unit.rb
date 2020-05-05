#
# Cookbook:: delivery-golang
# Recipe:: unit
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

load_config File.join(repo_path, '.delivery', 'config.json')

Chef::Log.info("No Golang Tests found for #{project_name}") if golang_test_project_packages.empty?

# Golang Tests
golang_test_project_packages.each do |go_package|
  delivery_golang_unit "test_#{go_package}" do
    package_name go_package
  end
end

# Unit Test for any cookbook we might have under cookbooks/
changed_cookbooks.each do |cookbook|
  # Run RSpec against the modified cookbook
  execute "unit_rspec_#{cookbook[:name]}" do
    cwd cookbook[:path]
    command 'berks install; rspec --format documentation --color'
    only_if { has_spec_tests?(cookbook[:path]) }
  end
end
