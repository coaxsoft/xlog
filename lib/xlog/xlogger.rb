# frozen_string_literal: true

module Xlog
  class Xlogger
    include Singleton

    attr_accessor :app_name, :app_root, :base_logger
    def initialize
      @base_logger = ActiveSupport::TaggedLogging.new(Logger.new("log/xlog_#{Rails.env}.log"))

      @app_name = Rails.application.class.to_s.split('::')[0].underscore
      @app_root = Rails.root.to_s
      @folder_names_to_remove = Dir.glob('app/*').map { |f| f.gsub('app/', '') }
    end

    def tag_logger(*tags)
      @tags = tags
    end

    def log(type, text)
      tags = [time_stamp, called_from(type), type] + Array.wrap(@tags)
      @base_logger.tagged(tags.compact) { @base_logger.send(type, text) }
    end

    def info(message, data)
      log(:info, compose_log(message, data))
    end

    def warn(message, data)
      log(:warn, compose_log(message, data))
    end

    # do NOT refactor error and and_raise_error
    # they MUST BE NOT DRY in order to log correct backtrace
    def error(e, message, data)
      log(:error, "#{e.class}: #{e.try(:message)}. \n #{compose_log(message, data)} \n Error backtrace: \n#{backtrace(e)}")
    end

    def and_raise_error(e, message, data)
      log(:error, "#{e.class}: #{e.try(:message)}. #{newline} #{compose_log(message, data)} #{newline} Error backtrace: #{newline} #{backtrace(e)}")
      message.present? ? raise(e, message) : raise(e)
    end

    def custom_logger=(logger)
      @base_logger = ActiveSupport::TaggedLogging.new(logger)
    end

    private

    def newline
      "\n  |"
    end

    def time_stamp
      Time.zone&.now || Time.current
    end

    def compose_log(message, data)
      message = "Message: #{message}"
      message += "#{newline} Data: #{data.try(:inspect)}" if data.present?
      message
    end

    def backtrace(e)
      backtrace_cleaner.clean(e.try(:backtrace)).try(:join, "#{newline} ")
    end

    def backtrace_cleaner
      return @backtrace_cleaner if @backtrace_cleaner.present?

      bc = ActiveSupport::BacktraceCleaner.new
      bc.add_filter   { |line| line.gsub(app_root, '') }
      bc.add_silencer { |line| line =~ /puma|rubygems|gems/ }
      @backtrace_cleaner = bc
    end

    def called_from(type)
      caller_position = type == :error ? 5 : 4
      caller(caller_position..caller_position)[0]
        .split("/#{app_name}/*")[-1]
        .split('.rb')[0]
        .remove(*@folder_names_to_remove)
        .split('//')[-1]
        .camelize
        .concat(".#{caller_locations(caller_position, caller_position + 1)[0].label}")
    end
  end
end
