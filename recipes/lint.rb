#
# Cookbook:: delivery-golang
# Recipe:: lint
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

load_config File.join(repo_path, '.delivery', 'config.json')

# Golang Lint Test
execute "Golang Lint Test for #{project_name}" do
  command 'golint ./...'
  cwd repo_path
  user 'dbuild'
  environment golang_environment
end

# Lint Test for any cookbook we might have under cookbooks/
changed_cookbooks.each do |cookbook|
  # Run Foodcritic against any cookbooks that were modified.
  execute "lint_foodcritic_#{cookbook[:name]}" do
    command "foodcritic -f correctness #{foodcritic_tags} #{cookbook[:path]}"
  end
end
