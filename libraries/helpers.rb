#
# Copyright:: Copyright (c) 2012-2015 Chef Software, Inc.
#

require 'chef/mixin/shell_out'

module DeliveryGolang
  module Helpers
    include Chef::Mixin::ShellOut
    extend self

    # The Golang Partial Path specified in the `.delivery/config.json`
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def delivery_golang_path(node)
      node[CONFIG_ATTRIBUTE_KEY]['build_attributes']['golang']['path']
    rescue
      project_name
    end

    # Golang Project Full Path
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def golang_project_path(node)
      "#{node['go']['gopath']}/src/#{delivery_golang_path(node)}"
    end

    # Golang Project Directory Name
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def golang_project_dirname(node)
      File.dirname(golang_project_path(node))
    end

    # Golang Environment Variables
    #
    # @param [Chef::Node] Chef Node object
    # @return [Hash]
    def golang_environment(node)
      {
        'GOPATH' => node['go']['gopath'],
        'GOBIN' => node['go']['gobin']
      }
    end

    # Golang Project Test Packages
    #
    # @return [Array]
    def golang_test_project_packages
      @@test_packages ||= begin
        go_test = Dir.glob("#{repo_path}/**/*_test.go")
        go_test.map! do |test|
          File.basename(File.dirname(test))
        end
      end
    end

    # Golang Exec
    #
    # @return [Array]
    def golang_exec(command, node)
      shell_out(
          command,
          :cwd => repo_path,
          :environment => golang_environment(node)
        ).stdout.strip
    end
  end

  module DSL
    # Get the Golang Partial Path
    def delivery_golang_path
      DeliveryGolang::Helpers.delivery_golang_path(node)
    end

    # Get the Golang Project Full Path
    def golang_project_path
      DeliveryGolang::Helpers.golang_project_path(node)
    end

    # Get the Golang Project Directory Name
    def golang_project_dirname
      DeliveryGolang::Helpers.golang_project_dirname(node)
    end

    # Get the Golang Environment Variables
    def golang_environment
      DeliveryGolang::Helpers.golang_environment(node)
    end

    # Execute a Golang command with specific context
    def golang_exec(command)
      DeliveryGolang::Helpers.golang_exec(command, node)
    end
  end
end
