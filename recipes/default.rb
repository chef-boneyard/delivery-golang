#
# Cookbook Name:: delivery-golang
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "golang"
include_recipe "delivery-truck"

# Golang packages
golang_package "github.com/golang/lint/golint" do
  action :install
end

# Nuke old golang project link
link golang_project_path do
  action :delete
  only_if "test -L #{golang_project_path}"
end

# Create directory tree
directory golang_project_dirname do
  owner node['go']['user']
  group node['go']['group']
  mode '0755'
  recursive true
end

# Link the Golang Project to the GOPATH Source Directory
link golang_project_path do
  to repo_path
end

