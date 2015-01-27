require 'slackattend'

# Encoding
Encoding.default_external = Encoding.find('UTF-8')

# Timezone setting
Time.zone = 'Asia/Tokyo'
ActiveRecord::Base.default_timezone = :local

#$stdout.sync = true #if development?
#\ -s puma -E production

Slackattend.setup
Slackattend.update_database
use Slackattend::WebsocketHandler
run Slackattend::App

