require "rack/utils"

module Rack
  class Idempotency
    class Response
      attr_reader :status, :headers, :body

      def initialize(status, headers, body)
        @status  = status.to_i
        @headers = Rack::Headers.new.merge(headers)
        @body    = body
      end

      def success?
        status.to_i >= 200 && status.to_i < 400
      end

      def to_a
        [status, headers.to_hash, body]
      end

      def to_json
        [status, headers.to_hash, body.each(&:to_s)].to_json
      end
    end
  end
end
