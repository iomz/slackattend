# -*- coding: utf-8 -*-
require "slack"
require "open-uri"

# init
token = Conf['token']
report_channel_name = Conf['report_channel_name']
excluded_users = Conf['excluded_users']

Slack.configure do |config|
  config.token = token
end

# Check the token validity
res = Slack.auth_test
if res['ok'] == false
  puts "token is not valid"
  exit
else
  puts "slack API access successful"
end

# Check slackattend channel, create one if none matched
ch_id = nil
channels = Slack.channels_list['channels']
channels.each do |c|
  if c['name'] == report_channel_name
    ch_id = c['id']
  end
end
if ch_id.nil?
  puts "creating #{report_channel_name}"
  res = Slack.channels_create(options = {:name => report_channel_name})
  pp res
  ch_id = res['channel']['id']
end
puts "using ##{report_channel_name} channel id: #{ch_id}"

# Update users based on Slack userlist
res = Slack.users_list(options = {})
res['members'].each do |u|
  username = u['name']
  avatar = u['profile']['image_original'] || u['profile']['image_192'] 
  unless excluded_users.include?(username)
    Status.create(name: username, status: "absent", updated_at: Time.now.to_f) if Status.where(:name => username).empty?
    Member.create(name: username, avatar: avatar)
  end
end

