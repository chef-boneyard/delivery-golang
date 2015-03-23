#
# Cookbook Name:: delivery-golang
# Recipe:: publish
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

require 'aws/s3'

load_config File.join(repo_path, '.delivery', 'config.json')

# Binary Directory
binary_path = "#{repo_path}/binary"
directory binary_path

# Build greentea package
golang_package delivery_golang_path do
  cwd binary_path
  action :build
end

# Upload Binary to S3 Bucket
ruby_block 'Upload Binary to S3 Bucket' do
  block do
    s3 = AWS::S3.new(
      :access_key_id => get_project_secrets['access_key_id'],
      :secret_access_key => get_project_secrets['secret_access_key']
     )
    s3.buckets[publish_s3_bucket].
      objects[project_name].
      write(Pathname.new("#{binary_path}/#{project_name}"))
  end
end

# Upload it to S3 Bucket

# Publish any cookbook we might have under cookbooks/ and
# push this project to github (if we specify it)

# Create the upload directory where cookbooks to be uploaded will be staged
cookbook_directory = File.join(node['delivery_builder']['cache'], "cookbook-upload")
directory cookbook_directory

# Create the environment if it doesn't exist
env_name = get_acceptance_environment
ruby_block "Create Env #{env_name} if not there." do
  block do
    Chef_Delivery::ClientHelper.load_delivery_user

    begin
      env = Chef::Environment.load(env_name)
    rescue Net::HTTPServerException => http_e
      raise http_e unless http_e.response.code == "404"
      Chef::Log.info("Creating Environment #{env_name}")
      env = Chef::Environment.new()
      env.name(env_name)
      env.create
    end
    Chef_Delivery::ClientHelper.return_to_zero
  end
end

# Upload each cookbook to the Chef Server
if upload_cookbook_to_chef_server?
  changed_cookbooks.each do |cookbook|
    link ::File.join(cookbook_directory, cookbook[:name]) do
      to cookbook[:path]
    end

    execute "upload_cookbook_#{cookbook[:name]}" do
      command "knife cookbook upload #{cookbook[:name]} --freeze " \
              "--env #{env_name} " \
              "--config #{delivery_chef_config} " \
              "--cookbook-path #{cookbook_directory}"
    end
  end
end

# If the user specified a github repo to push to, push to that repo
if push_repo_to_github?
  build_user_home = "/home/#{node['delivery_builder']['build_user']}"
  deploy_key_path = "#{build_user_home}/.ssh/#{project_slug}-github.pem"
  git_ssh = ::File.join(node['delivery_builder']['cache'], 'git_ssh')

  directory "#{build_user_home}/.ssh" do
    owner node['delivery_builder']['build_user']
    group 'root'
    mode '0700'
  end

  file deploy_key_path do
    content get_project_secrets['github']
    owner node['delivery_builder']['build_user']
    group 'root'
    mode '0600'
  end

  file git_ssh do
    content <<-EOH
#!/bin/bash
# Martin Emde
# https://github.com/martinemde/git-ssh-wrapper

unset SSH_AUTH_SOCK
ssh -o CheckHostIP=no \
    -o IdentitiesOnly=yes \
    -o LogLevel=INFO \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -o UserKnownHostsFile=/tmp/delivery-git-known-hosts \
    -o IdentityFile=/home/dbuild/.ssh/#{project_slug}-github.pem \
    $*
    EOH
    mode '0755'
  end

  execute "add_github_remote" do
    command "git remote add github git@github.com:#{github_repo}.git"
    cwd node['delivery_builder']['repo']
    environment({"GIT_SSH" => git_ssh})
    not_if "git remote --verbose | grep ^github"
  end

  execute "push_to_github" do
    command "git push github master"
    cwd node['delivery_builder']['repo']
    environment({"GIT_SSH" => git_ssh})
  end
end
