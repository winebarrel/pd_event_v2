# frozen_string_literal: true

module PdEventV2
  class Client
    INITIALIZE_OPTIONS = %i[
      routing_key
      debug
    ].freeze

    DEFAULT_ADAPTERS = [
      Faraday::Adapter::NetHttp,
      Faraday::Adapter::Test,
    ].freeze

    USER_AGENT = "PagerDuty Events API v2 Ruby Client #{PdEventV2::VERSION}"

    # https://v2.developer.pagerduty.com/docs/events-api-v2#making-a-request
    DEFAULT_API_URL = 'https://events.pagerduty.com/v2/enqueue'

    # https://v2.developer.pagerduty.com/docs/events-api-v2#event-action
    EVENT_ACTIONS = %i[
      trigger
      acknowledge
      resolve
    ].freeze

    # https://v2.developer.pagerduty.com/v2/docs/send-an-event-events-api-v2
    PAYLOAD_KEYS = {
      summary: true,
      source: true,
      severity: true,
      timestamp: false,
      component: false,
      group: false,
      class: false,
      custom_details: false,
    }.freeze

    def initialize(options)
      unless options.is_a?(Hash)
        raise ArgumentError, "wrong type argument (given: #{options}:#{options.class}, expected Hash)"
      end

      @options = {}

      INITIALIZE_OPTIONS.each do |key|
        @options[key] = options.delete(key)
      end

      raise ArgumentError, ':routing_key is required for initialize' unless @options[:routing_key]

      options[:url] ||= DEFAULT_API_URL

      @conn = Faraday.new(options) do |faraday|
        faraday.request :url_encoded
        faraday.response :json, content_type: /\bjson\b/
        faraday.response :raise_error
        faraday.response :logger, ::Logger.new(STDOUT), bodies: true if @options[:debug]

        yield(faraday) if block_given?

        unless DEFAULT_ADAPTERS.any? { |i| faraday.builder.handlers.include?(i) }
          faraday.adapter Faraday.default_adapter
        end
      end

      @conn.headers[:user_agent] = USER_AGENT
    end

    EVENT_ACTIONS.each do |action|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{action}(**args)
          send_event(event_action: '#{action}', **args)
        end
      RUBY
    end

    private

    # https://v2.developer.pagerduty.com/v2/docs/send-an-event-events-api-v2
    def send_event(event_action:, dedup_key: nil, payload:, images: nil, links: nil)
      unless payload.is_a?(Hash)
        raise ArgumentError, "wrong type payload (given: #{payload}:#{payload.class}, expected Hash)"
      end

      payload = payload.transform_keys(&:to_sym)

      PAYLOAD_KEYS.each do |key, required|
        raise ArgumentError, "missing payload key: #{key}" if required && !payload.key?(key)
      end

      routing_key = @options.fetch(:routing_key)

      params = {
        routing_key: routing_key,
        event_action: event_action,
        payload: payload,
      }

      params[:dedup_key] = dedup_key if dedup_key
      params[:images] = images if images
      params[:links] = links if links

      res = @conn.post do |req|
        req.body = JSON.dump(params)
        yield(req) if block_given?
      end

      res.body
    end
  end
end
