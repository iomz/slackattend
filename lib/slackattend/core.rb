module Slackattend
  module Core
    def config
      @config ||= {}
    end

    def load_config
      YAML.load_file(File.expand_path('../../../config.yml', __FILE__)).each{ |k,v| config[k.to_sym] = v }
    end

    def log_sojourn_time(user, action, logrotate=false)
      # validates the user is leaving the room
      unless action == :out
        return
      end
  
      from = StatusLog.where(:action => "in").order("id desc").find_by_user(user).created_at.to_time
      to = DateTime.now.to_time
      date = to.to_date
  
      # midnight logrotate
      if logrotate
        date = from.to_date
        to = Time.parse("23:59", date)
      # unless logrotate and overnight
      elsif from.to_date < date
        from = Time.parse("00:00")
      end
  
      # sojour time in minute
      minute = ((to - from)/60).to_i
      SojournTime.create(:user => user, :date => date, :from => from, :to => to, :minute => minute) unless minute == 0
    end

    def minutely_counter_update()
      now = DateTime.now.to_time.to_i
      now -= now%60
      count = CurrentMember.where(status: "in").count
      AttendanceCount.create(:date => Time.at(now).to_date, :time => Time.at(now), :count => count)
    end

    def midnight_rotate()
      CurrentMember.select("user, status") do |user, status|
        Slackattend.log_sojourn_time(user, status, logrotate=true)
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
    end
  end

  extend Core
  Slackattend.load_config
end

