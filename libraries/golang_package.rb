#
# Cookbook Name:: delivery-golang
# Library:: golang_package
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

require 'chef/mixin/shell_out'

class Chef
  class Provider
    class GolangPackage < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut

      action :get do
        converge_by("Installing package #{new_resource.name}") do
          shell_out!("go get -v -d -t #{new_resource.name}", options)
        end
      end

      action :build do
        converge_by("Installing package #{new_resource.name}") do
          shell_out!("go build #{new_resource.name}", options)
        end
      end

      action :install do
        converge_by("Installing package #{new_resource.name}") do
          shell_out!("go get -v #{new_resource.name}", options)
        end
      end

      action :update do
        converge_by("Installing package #{new_resource.name}") do
          shell_out!("go get -v -u #{new_resource.name}", options)
        end
      end

      private

      def options
        @options ||= begin
          opts = {}
          opts[:timeout] = 3600
          opts[:environment] = golang_environment
          opts[:user] = node['delivery-golang']['go']['user']
          opts[:group] = node['delivery-golang']['go']['group']
          opts[:cwd] = @new_resource.cwd if @new_resource.cwd
          opts[:log_level] = :info
          opts[:live_stream] = Chef::Log.logger
          opts
        end
      end

    end
  end
end

class Chef
  class Resource
    class GolangPackage < Chef::Resource::LWRPBase

      actions :get, :install, :update, :build
      default_action :get

      attribute :name,  :kind_of => String, :name_attribute => true
      attribute :cwd,   :kind_of => String

      self.resource_name = :golang_package

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::GolangPackage
      end
    end
  end
end
