#
# Cookbook:: delivery-golang
# Library:: helpers
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

require 'chef/mixin/shell_out'
require 'chef/cookbook/metadata'

module DeliveryGolang
  module Helpers
    include Chef::Mixin::ShellOut
    extend self

    # This value is also set in the delivery_builder cookbook. To avoid
    # depending on an external cookbook we are going to duplicate its definition
    # here.
    unless defined? CONFIG_ATTRIBUTE_KEY
      CONFIG_ATTRIBUTE_KEY = 'delivery_config'.freeze
    end

    # This method will load the Delivery configuration file. If we are running
    # on a Delivery Build Node, then the delivery_builder cookbook will have
    # already done this for us. If the config file has not been loaded then we
    # will need to load it ourselves.
    #
    # @param config_file [String] Fully-qualified path to Delivery config file.
    # @param node [Chef::Node] Chef Node object
    # @return [nil]
    def load_config(config_file, node)
      # Check to see if CONFIG_ATTRIBUTE_KEY is present. This is set by the
      # delivery_builder cookbook and will indicate that we are running on
      # a Delivery build node.
      if node[CONFIG_ATTRIBUTE_KEY]
        # We don't need to do anything since the delivery_builder cookbook has
        # already loaded the attributes.
      else
        # Check to see if the Delivery config exists in the project root. If it
        # does, then load it into the node object.
        if File.exist?(config_file)
          config = Chef::JSONCompat.from_json(IO.read(config_file))
          node.force_override[CONFIG_ATTRIBUTE_KEY] = config
        else
          raise "MissingConfiguration #{config_file}"
        end
      end
      nil
    end

    # Return the Standard Acceptance Environment Name
    #
    def get_acceptance_environment(node)
      if is_change_loaded?(node)
        change = node['delivery']['change']
        ent = change['enterprise']
        org = change['organization']
        proj = change['project']
        pipe = change['pipeline']
        "acceptance-#{ent}-#{org}-#{proj}-#{pipe}"
      end
    end

    # Return the Standard Delivery Environment Name
    #
    # @param [Chef::Node] Chef Node object
    # @param [String] Could Return:
    # => get_acceptance_environment
    # => union
    # => rehearsal
    # => delivered
    def delivery_environment(node)
      if is_change_loaded?(node)
        if node['delivery']['change']['stage'] == 'acceptance'
          get_acceptance_environment(node)
        else
          node['delivery']['change']['stage']
        end
      end
    end

    # Inspect the files that are different between the patchset and the current
    # HEAD of the pipeline branch. If any files related to a cookbook have
    # changed, return the name of that cookbook along with its path.
    #
    # @example Simple loop to exemplify how to access the name and path.
    #   changed_cookbooks.each do |cookbook|
    #     puts "Cookbook #{cookbook[:name]} has been modified."
    #     puts "It is avaialble at #{cookbook[:path]}"
    #   end
    #
    # @param node [Chef::Node] Chef Node object
    # @return [Array#Hash]
    def changed_cookbooks(node)
      modified_files = changed_files(
        pre_change_sha(node),
        change_sha(node),
        node
      )
      repo_dir = repo_path(node)

      changed_cookbooks = []
      cookbooks_in_repo(node).each do |cookbook|
        if cookbook == repo_dir && !modified_files.empty?
          name = get_cookbook_name(repo_dir)
          changed_cookbooks << { name: name, path: repo_dir }
        elsif !modified_files.select { |file| file.include? cookbook }.empty?
          path = File.join(repo_dir, cookbook)
          name = get_cookbook_name(path)
          changed_cookbooks << { name: name, path: path }
        end
      end

      changed_cookbooks
    end

    # Get a list of the paths for all the cookbooks in the current project
    # relative to the project root.
    #
    # There are two "happy paths" that this method is designed for. First is the
    # situation where the project is a cookbook (i.e. the Berkshelf Way). The
    # second is the monolithic chef repo where in the project root there is a
    # cookbooks directory where you keep all your cookbooks.
    #
    # This method is not designed to handle more than one cookbooks folder.
    #
    # @param node [Chef::Node] Chef Node object
    # @return [Array#String]
    def cookbooks_in_repo(node)
      # Is the current directory a cookbook?
      if is_cookbook?(repo_path(node))
        [repo_path(node)]

      # Is there a `cookbooks` directory in this directory?
      elsif File.directory?(File.join(repo_path(node), 'cookbooks'))
        # If so, return a list of the folders inside this directory but...
        Dir.chdir(repo_path(node)) do
          Dir.glob('cookbooks/*').select do |entry|
            full_path = File.join(repo_path(node), entry)

            # Make sure the entry is a directory and a cookbook
            File.directory?(full_path) && is_cookbook?(full_path)
          end
        end

      # It looks like there are no cookbooks in the directory
      else
        []
      end
    end

    # Get a list of the files that have changed between two shas and return them
    # as an array. This will typically be done to find the difference between
    # the latest patchset and the head of the pipeline.
    #
    # @param parent_sha [String] The SHA of the earlier commit.
    # @param change_sha [String] The SHA of the later commit.
    # @param node [Chef::Node] Chef Node object
    # @return [Array#String]
    def changed_files(parent_sha, change_sha, node)
      response = shell_out!(
        "git diff --name-only #{parent_sha} #{change_sha}",
        cwd: repo_path(node)
      ).stdout.strip

      changed_files = []
      response.each_line do |line|
        changed_files << line.strip
      end
      changed_files
    end

    # Return the SHA for the point in our history where we split off. For verify
    # this will be HEAD on the pipeline branch. For later stages, because HEAD
    # on the pipeline branch is our change, we will look for the 2nd most recent
    # commit to the pipeline branch.
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def pre_change_sha(node)
      branch = node['delivery']['change']['pipeline']

      if node['delivery']['change']['stage'] == 'verify'
        shell_out(
          "git rev-parse origin/#{branch}",
          cwd: repo_path(node)
        ).stdout.strip
      else
        # This command looks in the git history for the last two merges to our
        # pipeline branch. The most recent will be our SHA so the second to last
        # will be the SHA we are looking for.
        command = "git log origin/#{branch} --merges --pretty=\"%H\" -n2 | tail -n1"
        shell_out(command, cwd: repo_path(node)).stdout.strip
      end
    end

    # Rerturn the SHA that we are testing. For verify stage this will be the SHA
    # associated for the patchset. For later stages it will be the SHA for the
    # merge commit back into the pipeline branch.
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def change_sha(node)
      node['delivery']['change']['sha']
    end

    # Looks for indications that the directory passed is a Chef cookbook.
    #
    # @param path [String] Directory to check
    # @return [TrueClass, FalseClass]
    def is_cookbook?(path)
      File.exist?(File.join(path, 'metadata.json')) ||
        File.exist?(File.join(path, 'metadata.rb'))
    end

    # The list of cookbook under cookbooks/
    #
    #  @param [Chef::Node] Chef Node object
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

    # This method will leverage a core Chef library to load a cookbook's
    # metadata file and return the name of the cookbook.
    #
    # @param path [String] The path to the cookbook
    # @param [String]
    def get_cookbook_name(path)
      metadata = Chef::Cookbook::Metadata.new
      if File.exist?(File.join(path, 'metadata.json'))
        metadata.from_json_file(File.join(path, 'metadata.json'))
      else
        metadata.from_file(File.join(path, 'metadata.rb'))
      end
      metadata.name
    end

    # The Deployment Percentage per Rolling Cookbook specified
    # in the `.delivery/config.json`
    #
    #  @param [Chef::Node] Chef Node object
    #  @param [String] Cookbook name
    # @return [String]
    def delivery_golang_deploy_rolling(node, cookbook)
      node['delivery']['config']['build_attributes']['deploy']['rolling'][cookbook]
    rescue
      100
    end

    # The Golang Partial Path specified in the `.delivery/config.json`
    #
    #  @param [Chef::Node] Chef Node object
    # @return [String]
    def delivery_golang_path(node)
      node['delivery']['config']['build_attributes']['golang']['path']
    rescue
      project_name(node)
    end

    # Golang Package Dependencies specified in the `.delivery/config.json`
    #
    #  @param [Chef::Node] Chef Node object
    # @return [Array]
    def delivery_golang_packages(node)
      node['delivery']['config']['build_attributes']['golang']['packages']
    rescue
      []
    end

    # Golang Project Full Path
    #
    #  @param [Chef::Node] Chef Node object
    # @return [String]
    def golang_project_path(node)
      "#{node['delivery-golang']['go']['gopath']}/src/#{delivery_golang_path(node)}"
    end

    # Golang Project Directory Name
    #
    #  @param [Chef::Node] Chef Node object
    # @return [String]
    def golang_project_dirname(node)
      File.dirname(golang_project_path(node))
    end

    # Golang Environment Variables
    #
    #  @param [Chef::Node] Chef Node object
    # @return [Hash]
    def golang_environment(node)
      {
        'GOPATH' => node['delivery-golang']['go']['gopath'],
        'GOBIN' => node['delivery-golang']['go']['gobin'],
        'GIT_SSH' => git_ssh(node),
        'PATH' => "#{ENV['PATH']}:#{node['delivery-golang']['go']['gobin']}:#{node['delivery-golang']['go']['install_dir']}/go/bin",
      }
    end

    # Using identifying components of the change, generate a project slug.
    #
    # @param [Chef::Node] Chef Node object
    # @param [String]
    def project_slug(node)
      if is_change_loaded?(node)
        change = node['delivery']['change']
        ent = change['enterprise']
        org = change['organization']
        proj = change['project']
        "#{ent}-#{org}-#{proj}"
      end
    end

    def build_user_home(_node)
      '/var/opt/delivery/workspace'
    end

    # Return the project name
    #
    # @param [Chef::Node] Chef Node object
    # @param [String]
    def project_name(node)
      node['delivery']['change']['project'] if is_change_loaded?(node)
    end

    # Validate that the change is already loaded.
    def is_change_loaded?(node)
      if node['delivery']['change']
        true
      else
        message = <<-EOM
The value of
  node['delivery']['change']
has not been set yet!
I apologize profusely for this.
EOM
        raise "MissingChangeInformation #{message}"
      end
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
          cwd: repo_path(node),
          environment: golang_environment(node)
        ).stdout.strip
    end

    # Return the fully-qualified path to the root of the repo.
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def repo_path(node)
      node['delivery_builder']['repo'] || File.expand_path('..', __dir__)
    end

    def delivery_chef_config
      '/var/opt/delivery/workspace/.chef/knife.rb'
    end

    # Pull down the encrypted data bag containing the secrets for this project.
    #
    # @param [Chef::Node] Chef Node object
    # @return [Hash]
    def get_project_secrets(node)
      @@secrets ||= begin
        Chef_Delivery::ClientHelper.load_delivery_user
        secret_file = Chef::EncryptedDataBagItem.load_secret(Chef::Config[:encrypted_data_bag_secret])
        secrets = data_bag_item('delivery-secrets', project_slug(node), secret_file)
        Chef_Delivery::ClientHelper.return_to_zero
        secrets
      end
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

    # Return the SHA for the patchset currently being tested
    def change_sha
      DeliveryGolang::Helpers.change_sha(node)
    end

    # Return the SHA for the HEAD of the pipeline branch
    def pre_change_sha
      DeliveryGolang::Helpers.pre_change_sha(node)
    end

    def build_user_home
      DeliveryGolang::Helpers.build_user_home(node)
    end

    # Return a list of the cookbooks that have been modified
    def changed_cookbooks
      DeliveryGolang::Helpers.changed_cookbooks(node)
    end

    def deploy_key_path
      DeliveryGolang::Helpers.deploy_key_path(node)
    end

    # Load the Delivery configuration file into the node object
    def load_config(config_file)
      DeliveryGolang::Helpers.load_config(config_file, node)
    end

    def git_ssh
      DeliveryGolang::Helpers.git_ssh(node)
    end

    def get_cookbooks
      DeliveryGolang::Helpers.get_cookbooks(node)
    end

    def delivery_chef_config
      DeliveryGolang::Helpers.delivery_chef_config
    end

    # Return the Standard Delivery Environment Name
    def delivery_environment
      DeliveryGolang::Helpers.delivery_environment(node)
    end

    # Return the fully-qualified path to the root of the repo.
    def repo_path
      DeliveryGolang::Helpers.repo_path(node)
    end

    # Get the acceptance environment
    def get_acceptance_environment
      DeliveryGolang::Helpers.get_acceptance_environment(node)
    end

    # Return the project name
    def project_name
      DeliveryGolang::Helpers.project_name(node)
    end

    # Generate a project slug.
    def project_slug
      DeliveryGolang::Helpers.project_slug(node)
    end

    # Grab the data bag from the Chef Server where the secrets for this
    # project are kept
    def get_project_secrets
      DeliveryGolang::Helpers.get_project_secrets(node)
    end
  end
end
