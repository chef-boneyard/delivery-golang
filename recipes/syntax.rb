#
# Cookbook Name:: delivery-golang
# Recipe:: syntax
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

# Golang Syntax Test
execute "Golang Syntax Test for #{project_name}" do
  command "go vet ./..."
  cwd repo_path
  user 'dbuild'
  environment golang_environment
end

# Syntax Test for any cookbook we might have under cookbooks/
include_recipe "delivery-truck::syntax"
