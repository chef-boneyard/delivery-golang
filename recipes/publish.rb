#
# Cookbook Name:: delivery-golang
# Recipe:: publish
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

# Build greentea package
#
# For now it will be bundled into files/#{platform}
# with the deploy-#{project} cookbook
#
# TODO: Upload it to artifactory/application_repository
golang_package delivery_golang_path do
  cwd "#{repo_path}/cookbooks/deploy-#{project_name}/files/#{node['platform']}"
  action :build
end

# Publish any cookbook we might have under cookbooks/ and
# push this project to github (if we specify it)
include_recipe "delivery-truck::publish"
