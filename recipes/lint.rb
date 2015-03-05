#
# Cookbook Name:: delivery-golang
# Recipe:: lint
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

# Golang Lint Test
execute "Golang Lint Test for #{project_name}" do
  command "golint ./..."
  cwd repo_path
  user 'dbuild'
  environment golang_environment
end

# Lint Test for any cookbook we might have under cookbooks/
include_recipe "delivery-truck::lint"
