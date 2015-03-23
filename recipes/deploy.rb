#
# Cookbook Name:: delivery-golang
# Recipe:: deploy
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute

load_config File.join(repo_path, '.delivery', 'config.json')

# Rolling Deployments
#
# As part of this project needs, we must trigger a CCR always
# So we do the right deployment at the right time and order.
#
# TODO: Order them as they are shown in `.delivery/config.json`
# => "deploy": {
#       "rolling": {
#         "deploy-greentea": 20,
#         "lb-greentea": 100,
#         "audit": false
#       }
#     }
deploy_criteria = get_cookbooks.map do |cookbook|
  {
    "search" => "recipes:#{cookbook}*",
    "incremental" => delivery_golang_deploy_rolling(cookbook),
    "percentage" => delivery_golang_deploy_rolling(cookbook)
  }
end

# Only deploy the cookbooks you have modified? Uhmmm..
# deploy_criteria = changed_cookbooks.map { |cookbook| "recipes:#{cookbook[:name]}*" }

# Deploy incrementally
begin
  completed = true

  deploy_criteria.each do |criteria|
    if criteria['incremental']
      delivery_golang_deploy "deploy_#{project_name}_cookbook_#{criteria['search']}_#{criteria['percentage']}%" do
        search criteria['search']
        percentage criteria['percentage']
      end

      # Increment the percentage
      criteria['percentage'] += criteria['incremental'] if criteria['percentage'] < 100

      # Ensure we are not going further 100 percent
      criteria['percentage'] = 100 if criteria['percentage'] > 100

      # We have not completed
      completed = false if criteria['percentage'] != 100
    end
  end

  # Deploy until we have completed
end until completed
