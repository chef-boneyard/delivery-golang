#
# Cookbook Name:: delivery-golang
# Recipe:: publish
#
# Copyright (c) 2015 The Authors, All Rights Reserved.


# Publish any cookbook we might have under cookbooks/ and
# push this project to github (if we specify it)
include_recipe "delivery-truck::publish"
