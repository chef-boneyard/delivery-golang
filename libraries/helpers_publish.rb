#
# Copyright:: Copyright (c) 2012-2015 Chef Software, Inc.
#

module DeliveryGolang
  module Helpers
    module Publish
      extend self

      # Read the Delivery Config to see if the user has indicated they want their
      # cookbooks uploaded to Delivery's Chef Server. This is an intermediate
      # solution until more flexible endpoints are developed.
      #
      # @param [Chef::Node] Chef Node object
      # @return [TrueClass, FalseClass]
      def upload_cookbook_to_chef_server?(node)
        node['delivery']['config']['build_attributes']['publish']['chef_server']
      rescue
        false
      end

      # Read the Delivery Config to see if the uesr has indicated a Github
      # repo they would like to push to.
      #
      # @param [Chef::Node] Chef Node object
      # @return [TrueClass, FalseClass]
      def push_repo_to_github?(node)
        !!node['delivery']['config']['build_attributes']['publish']['github']
      rescue
        false
      end

      # Read the Delivery Config to get S3 bucket name
      #
      # @param [Chef::Node] Chef Node object
      # @return [String]
      def publish_s3_bucket(node)
        node['delivery']['config']['build_attributes']['publish']['s3_bucket']
      end

      # Read the Delivery Config and return the value of the Github repo the
      # user would like to push to.
      #
      # @param [Chef::Node] Chef Node object
      # @return [String]
      def github_repo(node)
        node['delivery']['config']['build_attributes']['publish']['github']
      end
    end
  end

  module DSL
    # Check config.json for whether user wants to upload to Chef Server
    def upload_cookbook_to_chef_server?
      DeliveryGolang::Helpers::Publish.upload_cookbook_to_chef_server?(node)
    end

    # Check config.json for whether user wants to push to Github
    def push_repo_to_github?
      DeliveryGolang::Helpers::Publish.push_repo_to_github?(node)
    end

    # Return the github repo the user would like to push to
    def github_repo
      DeliveryGolang::Helpers::Publish.github_repo(node)
    end

    # Return the github repo the user would like to push to
    def publish_s3_bucket
      DeliveryGolang::Helpers::Publish.publish_s3_bucket(node)
    end
  end
end
