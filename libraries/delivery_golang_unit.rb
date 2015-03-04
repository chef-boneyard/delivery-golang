#
# Copyright:: Copyright (c) 2012-2015 Chef Software, Inc.
#

class Chef
  class Provider
    class DeliveryGolangUnit < Chef::Provider::LWRPBase
      action :run do
        converge_by("Golang Test for Package [#{new_resource.package_name}]") do
          new_resource.updated_by_last_action(run_tests)
        end
      end

      private

      def run_tests
        Chef::Log.info("-------------------")
        Chef::Log.info(golang_exec(test_command(@new_resource.package_name)))
        Chef::Log.info("Coverage Summary")
        Chef::Log.info("-------------------")
        if File.exists?(coverage_full_path)
          Chef::Log.info(golang_exec(coverage_command(@new_resource.package_name)))
          File.delete(coverage_full_path)
        end
        true
      end

      def test_command(pkg)
        <<-CMD.gsub(/^\s+/, "").gsub(/\n/, " ")
          go test -parallel 5
            -coverpkg #{delivery_golang_path}/#{pkg}
            -coverprofile cover_#{pkg}.out
            #{delivery_golang_path}/#{pkg}
        CMD
      end

      def coverage_command(pkg)
        "go tool cover -func=cover_#{pkg}.out"
      end

      def coverage_full_path
        "#{repo_path}/cover_#{@new_resource.package_name}}.out"
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryGolangUnit < Chef::Resource::LWRPBase

      actions :run
      default_action :run

      attribute :package_name,  :kind_of => String
      self.resource_name = :delivery_golang_unit
      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryGolangUnit
      end
    end
  end
end
