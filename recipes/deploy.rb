#
# Cookbook Name:: delivery-golang
# Recipe:: deploy
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

# Doing rolling deployments
#
# As part of this project needs, we must trigger a CCR always
# So we do the right deployment at the right time and order.
load_config File.join(repo_path, '.delivery', 'config.json')

search_criteria = get_cookbooks.map {|cookbook| "recipes:#{cookbook}*" }

percentage = 0

# Deploy incrementally
begin
  # Increment the percentage
  percentage += delivery_golang_deploy_percentage

  # Ensure we are not going further 100 percent
  percentage = 100 if percentage > 100

  search_criteria.each do |cookbook|
    delivery_golang_deploy "deploy_#{project_name}_cookbook_#{cookbook}_#{percentage}" do
      search cookbook
      percentage percentage
    end
  end
end while percentage < 100
