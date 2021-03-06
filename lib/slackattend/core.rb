module Slackattend
  module Core
    # time at midnight
    MIDNIGHT = '00:00'.freeze

    def config
      @config ||= {}
    end

    def load_config
      YAML.load_file(File.expand_path('../../../config.yml', __FILE__)).each{ |k,v| config[k.to_sym] = v }
    end

    def log_sojourn_time(user, action, logrotate=false)
      # validates the user is leaving the room
      unless (action == :out) ^ logrotate
        return
      end
  
      from = StatusLog.where(:action => "in").order("id desc").find_by_user(user).created_at.to_time
      to = DateTime.now.to_time
      date = to.to_date
  
      # midnight logrotate
      if logrotate
        to = Time.parse(MIDNIGHT, date)
        from = Time.parse(MIDNIGHT, date.prev_day) if from.to_date < date.prev_day
      # unless logrotate and overnight
      elsif from.to_date < date
        from = Time.parse(MIDNIGHT)
      end
  
      # sojour time in minute
      minute = ((to - from)/60).to_i
      SojournTime.create(:user => user, :from => from, :to => to, :minute => minute) unless minute == 0
    end

    def minutely_counter_update()
      now = DateTime.now.to_time.to_i
      now -= now%60
      count = CurrentMember.where(status: "in").count
      AttendanceCount.create(:time => Time.at(now), :count => count)
    end

    def midnight_rotate()
      CurrentMember.select(:user, :status).each do |m|
        Slackattend.log_sojourn_time(m.user, m.status.to_sym, logrotate=true)
      end
    end

    def log_start()
      t = Thread.new do
        interval = 60 #seconds
        loop do
          now = DateTime.now.to_time.to_i
          sleep interval - (now%interval)
          minutely_counter_update
          midnight_rotate if Time.at(now).strftime("%H%M") == '0'*4
        end
      end
      t.abort_on_exception = true
    end

    def rtm_start()
      puts "* Starting a slack RTM client: slackattend2"
      t = Thread.new do
        c = Slackattend.get_rtm_client
        c.on(:message) do |data|
          ch = Slackattend.get_channel_name(data['channel'])
          begin
            usr = Slackattend.get_user_name(data['user'])
          rescue
            usr = 'unknown'
          end
          unless usr == 'unknown' or usr == 'slackattend'
            txt = data['text']
            p "#{usr}@#{ch}: #{txt}"
            case Slackattend::SentimentAnalyzer.judge(txt)[0]
            when :positive
              reply = ["いいじゃん", "おっけー", "よかったね"].sample
            when :negative
              reply = ["がんばって！", "だいじょうぶ？", "はやくげんきになってね"].sample
            when :neutral
              reply = ["りょうかい", "わかりました", "はい"].sample
            end
            Slackattend.post("@#{usr}: #{reply}")
          end
        end
        c.start
      end
      t.abort_on_exception = true
    end
  end

  extend Core
  Slackattend.load_config
end

