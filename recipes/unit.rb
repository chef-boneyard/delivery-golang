#
# Cookbook Name:: delivery-golang
# Recipe:: unit
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

Chef::Log.info("No Golang Tests found for #{project_name}") if golang_test_project_packages.empty?

# Golang Tests
golang_test_project_packages.each do |go_package|
  delivery_golang_unit "test_#{go_package}" do
    package_name go_pkg
  end
end

# Unit Test for any cookbook we might have under cookbooks/
include_recipe "delivery-truck::unit"
