#
# Cookbook Name:: delivery-golang
# Recipe:: default
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

include_recipe "delivery-golang::_golang"

# Nuke old golang project link
link golang_project_path do
  action :delete
  only_if "test -L #{golang_project_path}"
end

# Create directory tree
directory golang_project_dirname do
  owner node['delivery-golang']['go']['user']
  group node['delivery-golang']['go']['group']
  mode '0755'
  recursive true
end

# Link the Golang Project to the GOPATH Source Directory
link golang_project_path do
  to repo_path
end

# Commenting this to lay down the private key since we must have it
# if push_repo_to_github?
directory "#{build_user_home}/.ssh" do
  owner node['delivery_builder']['build_user']
  group 'root'
  mode '0700'
end

file deploy_key_path do
  content get_project_secrets['github']
  owner node['delivery_builder']['build_user']
  group 'root'
  mode '0600'
end

file git_ssh do
  content <<-EOH
#!/bin/bash
# Martin Emde
# https://github.com/martinemde/git-ssh-wrapper

unset SSH_AUTH_SOCK
ssh -o CheckHostIP=no \
  -o IdentitiesOnly=yes \
  -o LogLevel=INFO \
  -o StrictHostKeyChecking=no \
  -o PasswordAuthentication=no \
  -o UserKnownHostsFile=/tmp/delivery-git-known-hosts \
  -o IdentityFile=#{deploy_key_path} \
  $*
  EOH
  mode '0755'
end
# end

# Get all Golang Package Dependencies
delivery_golang_packages.each do |pkg|
  golang_package pkg do
    action :install
  end
end

golang_package delivery_golang_path

#
# Temporary workaround until we reliably use a newer version of ChefDK
chef_gem 'chefspec' do
  version '4.2.0'
end

