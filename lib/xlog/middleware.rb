# frozen_string_literal: true

module Xlog
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @status, @headers, @response = @app.call(env)
    rescue StandardError => e
      Xlog.and_raise_error(e, data: { request_params: Rack::Request.new(env).params, status: @status, headers: @headers, response: @response })
    end
  end
end
