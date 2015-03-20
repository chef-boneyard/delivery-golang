#
# Cookbook Name:: delivery-golang
# Library:: helpers
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

require 'chef/mixin/shell_out'

module DeliveryGolang
  module Helpers
    include Chef::Mixin::ShellOut
    include DeliveryTruck::Helpers
    extend self

    # The list of cookbook under cookbooks/
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def get_cookbooks(node)
      cookbooks = []

      if File.directory?(File.join(repo_path(node), 'cookbooks'))
        Dir.chdir(repo_path(node)) do
          Dir.glob('cookbooks/*').select do |entry|
            full_path = File.join(repo_path(node), entry)

            # Make sure the entry is a directory and a cookbook
            if File.directory?(full_path) && is_cookbook?(full_path)
              cookbooks << get_cookbook_name(full_path)
            end
          end
        end
      end

      cookbooks
    end

    # The Deployment Percentage per Rolling Cookbook specified
    # in the `.delivery/config.json`
    #
    # @param [Chef::Node] Chef Node object
    # @param [String] Cookbook name
    # @return [String]
    def delivery_golang_deploy_rolling(node, cookbook)
      node[CONFIG_ATTRIBUTE_KEY]['build_attributes']['deploy']['rolling'][cookbook]
    rescue
      100
    end

    # The Golang Partial Path specified in the `.delivery/config.json`
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def delivery_golang_path(node)
      node[CONFIG_ATTRIBUTE_KEY]['build_attributes']['golang']['path']
    rescue
      project_name(node)
    end

    # Golang Package Dependencies specified in the `.delivery/config.json`
    #
    # @param [Chef::Node] Chef Node object
    # @return [Array]
    def delivery_golang_packages(node)
      node[CONFIG_ATTRIBUTE_KEY]['build_attributes']['golang']['packages']
    rescue
      []
    end

    # Golang Project Full Path
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def golang_project_path(node)
      "#{node['delivery-golang']['go']['gopath']}/src/#{delivery_golang_path(node)}"
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
        'GOPATH' => node['delivery-golang']['go']['gopath'],
        'GOBIN' => node['delivery-golang']['go']['gobin'],
        'GIT_SSH' => git_ssh(node),
        'PATH' => "#{ENV['PATH']}:#{node['delivery-golang']['go']['gobin']}:#{node['delivery-golang']['go']['install_dir']}/go/bin"
      }
    end

    # Pull down the encrypted data bag containing the secrets for this project.
    #
    # @param [Chef::Node] Chef Node object
    # @return [Hash]
    def get_secrets(node)
      secret_file = Chef::EncryptedDataBagItem.load_secret(Chef::Config[:encrypted_data_bag_secret])
      secrets = Chef::EncryptedDataBagItem.load('delivery-secrets', project_slug(node), secret_file)
      secrets
    end

    def build_user_home(node)
      "/home/#{node['delivery_builder']['build_user']}"
    end

    def deploy_key_path(node)
      "#{build_user_home(node)}/.ssh/#{project_slug(node)}-github.pem"
    end

    def git_ssh(node)
      ::File.join(node['delivery_builder']['cache'], 'git_ssh')
    end

    # Golang Project Test Packages
    #
    # @return [Array]
    def golang_test_project_packages(node)
      @@test_packages ||= begin
        go_test = Dir.glob("#{repo_path(node)}/**/*_test.go")
        go_test.map! do |test|
          File.basename(File.dirname(test))
        end
      end
    end

    # Golang Exec
    #
    # @return [Array]
    def golang_exec(command, node)
      shell_out!(
          command,
          :cwd => repo_path(node),
          :environment => golang_environment(node)
        ).stdout.strip
    end
  end

  module DSL
    # Get the Golang Partial Path
    def delivery_golang_path
      DeliveryGolang::Helpers.delivery_golang_path(node)
    end

    # Get the deploy percentage per rolling cookbook
    def delivery_golang_deploy_rolling(cookbook)
      DeliveryGolang::Helpers.delivery_golang_deploy_rolling(node, cookbook)
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

    # Get the Golang Project Test Packages
    def golang_test_project_packages
      DeliveryGolang::Helpers.golang_test_project_packages(node)
    end

    # Get Golang Package Dependencies
    def delivery_golang_packages
      DeliveryGolang::Helpers.delivery_golang_packages(node)
    end

    # Get Golang Package Dependencies
    def configure_github
      DeliveryGolang::Helpers.configure_github(node)
    end

    def get_secrets
      DeliveryGolang::Helpers.get_secrets(node)
    end

    def build_user_home
      DeliveryGolang::Helpers.build_user_home(node)
    end

    def deploy_key_path
      DeliveryGolang::Helpers.deploy_key_path(node)
    end

    def git_ssh
      DeliveryGolang::Helpers.git_ssh(node)
    end

    def get_cookbooks
      DeliveryGolang::Helpers.get_cookbooks(node)
    end
  end
end
