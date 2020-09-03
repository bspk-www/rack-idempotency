module Rack
  class Idempotency
    class RequestStorage
      def initialize(store, request, expires_in: 0)
        @store      = store
        @request    = request
        @expires_in = expires_in
      end

      def read
        return unless request.idempotency_key

        stored = store.read(storage_key)
        JSON.parse(stored) if stored
      end

      def write(response)
        return unless request.idempotency_key

        store.write(storage_key, response.to_json, expires_in: expires_in)
      end

      private

      attr_reader :request
      attr_reader :store
      attr_reader :expires_in

      def storage_key
        "rack:idempotency:" + request.idempotency_key
      end
    end
  end
end
