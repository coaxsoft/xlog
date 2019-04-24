require 'rails'
require 'xlog/version'

module Xlog

  class Log
    include Singleton

    class << self
      attr_accessor :config, :app_name, :app_root, :base_logger

      def tag_logger(*tags)
        instance.tag_logger(tags)
      end

      def info(message, data: nil)
        instance.info(message, data)
      end

      def warn(message, data: nil)
        instance.warn(message, data)
      end

      def error(e, message: nil, data: nil)
        instance.error(e, message, data)
      end

      def and_raise_error(e, message: nil, data: nil)
        instance.and_raise_error(e, message, data)
      end
    end

    def tag_logger(*tags)
      @tags = tags
    end

    def log(type, text)
      tags = [(Time.zone&.now Time.current), called_from(type), type] + Array.wrap(@tags)
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
    # rubocop:disable Metrics/LineLength
    def error(e, message, data)
      log(:error, "Error! #{e.class}: #{e.try(:message)}. #{message} \n #{compose_log(message, data)} \n Error backtrace: \n#{backtrace(e)}")
    end

    def and_raise_error(e, message, data)
      log(:error, "Error! #{e.class}: #{e.try(:message)}. #{message} \n #{compose_log(message, data)} \n Error backtrace: \n#{backtrace(e)}")
      message.present? ? raise(e, message) : raise(e)
    end

    private

    def compose_log(message, data)
      message = message.to_s + "; Data: #{data.try(:inspect)}" if data.present?
      message
    end

    def backtrace(e)
      backtrace_cleaner.clean(e.try(:backtrace)).try(:join, "\n")
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
      caller(caller_position..caller_position).first.split("#{app_name}/").last.split('.rb').first
          .remove(*@folder_names_to_remove)
          .camelize
          .concat(".#{caller_locations(caller_position, caller_position + 1)[0].label}")
    end
  end

  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
  end

  class Config
    attr_accessor :policy, :raise_policy_missed_error
    attr_reader :policy_file

    def initialize
      @base_logger = ActiveSupport::TaggedLogging.new(Logger.new("log/tagged_#{Rails.env}.log"))

      @app_name = Rails.application.class.to_s.split('::')[0].underscore
      @app_root = Rails.root.to_s
      @folder_names_to_remove = Dir.glob('app/*').map { |f| f.delete('app/') }
    end
  end

  configure {}
end

initializer = './config/initializers/xlog.rb'
require initializer if File.exist?(initializer)
