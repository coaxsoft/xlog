# frozen_string_literal: true

require 'rails'
require 'active_support/core_ext/time/zones'
require 'active_support/core_ext/time/calculations'
require_relative 'xlog/xlogger'
require_relative 'xlog/version'
require_relative 'xlog/middleware'

module Xlog
  class << self
    attr_accessor :config, :app_name, :app_root, :base_logger, :xlogger

    # rubocop:disable Layout/LineLength
    def tag_logger(*_tags)
      puts "\e[33mWARING: 'tag_logger' is no longer supported as it's not thread safe. Use 'tags: ' named argument instead for 'info', 'warn', 'error', 'and_raise_error'.\e[0m"
    end
    # rubocop:enable Layout/LineLength

    def clear_tags
      puts "\e[33mWARING: 'clear_tags' is no longer supported as it's not thread safe\e[0m"
    end

    def info(message, data: nil, tags: [])
      config.xlogger.info(message, data, tags)
    end

    def warn(message, data: nil, tags: [])
      config.xlogger.warn(message, data, tags)
    end

    def error(e, message: nil, data: nil, tags: [])
      config.xlogger.error(e, message, data, tags)
    end

    def and_raise_error(e, message: nil, data: nil, tags: [])
      config.xlogger.and_raise_error(e, message, data, tags)
    end
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
  end

  class Config
    attr_accessor :xlogger

    def initialize
      @xlogger = Xlogger.instance
    end

    def custom_logger=(logger)
      xlogger.custom_logger = logger
    end
  end

  configure {}
end
