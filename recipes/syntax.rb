#
# Cookbook Name:: delivery-golang
# Recipe:: syntax
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

load_config File.join(repo_path, '.delivery', 'config.json')

# Golang Syntax Test
execute "Golang Syntax Test for #{project_name}" do
  command "go vet ./..."
  cwd repo_path
  user 'dbuild'
  environment golang_environment
end

# Syntax Test for any cookbook we might have under cookbooks/
changed_cookbooks.each do |cookbook|
  # Run `knife cookbook test` against the modified cookbook
  execute "syntax_check_#{cookbook[:name]}" do
    command "knife cookbook test -c #{delivery_chef_config} -o #{cookbook[:path]} -a"
  end
end
