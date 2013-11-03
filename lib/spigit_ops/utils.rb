require 'net/smtp'

module SpigitOps
  class Utils

    def self.win_to_unix(time)
      begin
      	time.to_i if String === time
        windows_time = time
        unix_time    = windows_time / 10000000 - 11644473600

        unix_time
      rescue Exception => e
        puts "error: #{e.message}"
      end
    end

    def self.unix_to_win(time)
      begin
      	time.to_i if String === time
        unix_time    = time
        windows_time = (unix_time + 11644473600) * 10000000

        windows_time
      rescue Exception => e
        puts "error: #{e.message}"
      end
    end

    def self.send_email(options = {})
    	# type lookup
    	type    = { text: "text/plain", html: "text/html" }

      host    = options[:host]    ? options[:host]    : "localhost"

    	from    = options[:from]    ? options[:from]    : "operations-team@spigit.com"
    	to      = options[:to]      ? options[:to]      : "operations-team@spigit.com"
    	subject = options[:subject] ? options[:subject] : raise("Must declare a subject for email")
    	message = options[:message] ? options[:message] : raise("Must declare a message for email")
    	format  = options[:format]  ? options[:format]  : "text"

    	content_type  = type.has_key?(format.to_sym) ? type[format.to_sym] : type["text"]

      if Array === to
        to_header = to.join(', ')
      elsif String === to
        to_header = to
      else
        to_header = to
      end

message = <<MESSAGE_END
From: #{from}
To: #{to_header}
Subject: #{subject}
Mime-Version: 1.0
Content-Type: #{content_type}
Content-Disposition: inline

#{message}
MESSAGE_END

    	Net::SMTP.start(host, 25) do |smtp|
    	  smtp.send_message message, from, to
    	end
    end

  end
end
