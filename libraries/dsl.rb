#
# Copyright:: Copyright (c) 2012-2015 Chef Software, Inc.
#

require_relative 'helpers'

# And these mix the DSL methods into the Chef infrastructure
Chef::Recipe.send(:include, DeliveryGolang::DSL)
Chef::Resource.send(:include, DeliveryGolang::DSL)
Chef::Provider.send(:include, DeliveryGolang::DSL)
