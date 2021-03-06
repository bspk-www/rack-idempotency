require "json"

require "rack/idempotency/version"

require "rack/idempotency/errors"
require "rack/idempotency/memory_store"
require "rack/idempotency/null_store"
require "rack/idempotency/request"
require "rack/idempotency/request_storage"
require "rack/idempotency/response"

module Rack
  # Rack middleware for ensuring mutating endpoints are called at most once.
  #
  # Any request with an `Idempotency-Key` header will store its response in
  # the given cache.  When the client retries, it will get the previously
  # cached response.
  class Idempotency
    def initialize(app, store: NullStore.new, expires_in: 0)
      @app        = app
      @store      = store
      @expires_in = expires_in
    end

    def call(env)
      request = Request.new(env.dup.freeze)
      storage = RequestStorage.new(@store, request, expires_in: @expires_in)

      storage.read || store_response(storage, env)
    end

    private

    def store_response(storage, env)
      response = Response.new(*@app.call(env))

      storage.write(response) if response.success?

      response.to_a
    end
  end
end
