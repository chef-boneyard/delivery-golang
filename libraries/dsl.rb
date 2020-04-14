#
# Cookbook:: delivery-golang
# Library:: dsl
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

require_relative 'helpers'
require_relative 'helpers_functional'
require_relative 'helpers_lint'
require_relative 'helpers_unit'
require_relative 'helpers_publish'

# And these mix the DSL methods into the Chef infrastructure
Chef::Recipe.include DeliveryGolang::DSL
Chef::Resource.include DeliveryGolang::DSL
Chef::Provider.include DeliveryGolang::DSL
