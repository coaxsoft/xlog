# frozen_string_literal: true
TEST_LOG = 'log/test_custom_logger.log'.freeze
RSpec.describe Xlog do
  it 'has a version number' do
    expect(Xlog::VERSION).not_to be nil
  end

  describe 'initialize' do
    it 'inits base_logger' do
      expect(Xlog.config.xlogger.base_logger.class).to eq Logger
    end
  end

  describe 'configure' do
    let!(:custom_logger) { Logger.new(TEST_LOG) }
    before do
      Xlog.configure do |config|
        config.custom_logger = custom_logger
      end
    end
    it 'changes base_logger' do
      expect(Xlog.config.xlogger.base_logger).to be custom_logger
    end
  end

  describe 'logging' do
    before do
      Xlog.configure do |config|
        config.custom_logger = Logger.new(TEST_LOG)
      end
      File.truncate(TEST_LOG, 0)
    end

    after do
      File.truncate(TEST_LOG, 0)
    end

    context '.info' do
      let(:message) { Faker::Lorem.sentence }

      it 'logs message with info tag' do
        Xlog.info(message)
        expect(log_text).to include(message)
        expect(log_text).to include('[info]')
      end
    end

    context '.warn' do
      let(:message) { Faker::Lorem.sentence }

      it 'logs message with warn tag' do
        Xlog.warn(message)
        expect(log_text).to include(message)
        expect(log_text).to include('[warn]')
      end
    end

    context '.error' do
      let(:message) { Faker::Lorem.sentence }

      it 'logs message with error tag' do
        raise StandardError.new
      rescue StandardError => e
        Xlog.error(e, message: message)
        expect(log_text).to include(message)
        expect(log_text).to include('[error]')
        expect(log_text).to include('Error backtrace')
        expect(log_text).to include('xlog/spec/xlog_spec.rb')
      end
    end
  end
end
