require 'slackattend'

# ActiveRecord debug message
ActiveRecord::Base::logger.level = 1

# Encoding
Encoding.default_external = Encoding.find('UTF-8')

# Timezone setting
Time.zone = 'Asia/Tokyo'
ActiveRecord::Base.default_timezone = :local

#$stdout.sync = true #if development?
#\ -s puma -E production

Slackattend.setup
Slackattend.log_start
Slackattend.rtm_start

use Slackattend::WebsocketHandler
run Slackattend::App

