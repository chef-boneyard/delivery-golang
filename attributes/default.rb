#
# Cookbook:: delivery-golang
# Attribute:: default
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

default['delivery-golang']['go']['version'] = '1.4'
default['delivery-golang']['go']['platform'] = node['kernel']['machine'] =~ /i.86/ ? '386' : 'amd64'
default['delivery-golang']['go']['filename'] = "go#{node['delivery-golang']['go']['version']}.#{node['os']}-#{node['delivery-golang']['go']['platform']}.tar.gz"
default['delivery-golang']['go']['url'] = "http://golang.org/dl/#{node['delivery-golang']['go']['filename']}"
default['delivery-golang']['go']['install_dir'] = '/usr/local'
default['delivery-golang']['go']['gopath'] = '/opt/go'
default['delivery-golang']['go']['gobin'] = '/opt/go/bin'
default['delivery-golang']['go']['scm'] = true
default['delivery-golang']['go']['packages'] = []
default['delivery-golang']['go']['owner'] = 'root'
default['delivery-golang']['go']['group'] = 'root'
default['delivery-golang']['go']['mode'] = 0755
