#
# Cookbook Name:: delivery-golang
# Recipe:: lint
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Golang Lint Test
delivery_truck_exec "push_to_github" do
  command "go vet ./..."
  cwd repo_path
  environment ({
    "GIT_SSH" => git_ssh
    })
end

# Lint Test for any cookbook we might have under cookbooks/
include_recipe "delivery-truck::lint"
