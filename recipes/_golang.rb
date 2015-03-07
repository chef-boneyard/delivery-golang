#
# Cookbook Name:: delivery-golang
# Recipe:: _golang
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute


bash "install-golang" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    rm -rf go
    rm -rf #{node['delivery-golang']['go']['install_dir']}/go
    tar -C #{node['delivery-golang']['go']['install_dir']} -xzf #{node['delivery-golang']['go']['filename']}
  EOH
  action :nothing
end

remote_file File.join(Chef::Config[:file_cache_path], node['delivery-golang']['go']['filename']) do
  source node['delivery-golang']['go']['url']
  owner 'root'
  mode 0644
  notifies :run, 'bash[install-golang]', :immediately
  not_if "#{node['delivery-golang']['go']['install_dir']}/go/bin/go version | grep \"go#{node['delivery-golang']['go']['version']} \""
end

directory node['delivery-golang']['go']['gopath'] do
  action :create
  recursive true
  owner node['delivery-golang']['go']['owner']
  group node['delivery-golang']['go']['group']
  mode node['delivery-golang']['go']['mode']
end

directory node['delivery-golang']['go']['gobin'] do
  action :create
  recursive true
  owner node['delivery-golang']['go']['owner']
  group node['delivery-golang']['go']['group']
  mode node['delivery-golang']['go']['mode']
end

file "/etc/profile.d/golang.sh" do
  content <<-EOF
export PATH=$PATH:#{node['delivery-golang']['go']['install_dir']}/go/bin:#{node['delivery-golang']['go']['gobin']}
export GOPATH=#{node['delivery-golang']['go']['gopath']}
export GOBIN=#{node['delivery-golang']['go']['gobin']}
  EOF
  owner 'root'
  group 'root'
  mode 0755
end

if node['delivery-golang']['go']['scm']
  %w(git mercurial).each do |scm|
    package scm
  end
end
