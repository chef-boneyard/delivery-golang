#
# Cookbook Name:: delivery-golang
# Recipe:: syntax
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Golang Syntax Test
delivery_truck_exec "Golang Syntax Test for #{project_name}" do
  command "go vet ./..."
  cwd repo_path
  user node['go']['owner']
  group node['go']['group']
  environment({
    'GOPATH' => node['go']['gopath'],
    'GOBIN' => node['go']['gobin']
  })
end

# Syntax Test for any cookbook we might have under cookbooks/
include_recipe "delivery-truck::syntax"
