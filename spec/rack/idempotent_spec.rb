require "spec_helper"

RSpec.describe Rack::Idempotency do
  let(:app) { lambda { |_| [200, { "Content-Type" => "text/plain" }, [SecureRandom.uuid]] } }
  let(:middleware) { Rack::Idempotency.new(app, store: Rack::Idempotency::MemoryStore.new) }
  let(:request) { Rack::MockRequest.new(middleware) }
  let(:key) { SecureRandom.uuid }

  it "has a version number" do
    expect(Rack::Idempotency::VERSION).not_to be nil
  end

  it "should allow to pass expires_in on initialization" do
    store = Rack::Idempotency::MemoryStore.new
    middleware = Rack::Idempotency.new(app, store: store, expires_in: 600)

    expect(store).to receive(:write).with(instance_of(String), instance_of(String), expires_in: 600).and_call_original

    request = Rack::MockRequest.new(middleware)
    request.get("/", "HTTP_IDEMPOTENCY_KEY" => SecureRandom.uuid)
  end

  context "without an idempotency key" do
    subject { request.get("/").body }

    it { is_expected.to_not be_nil }
  end

  context "with insecure idempotency key" do
    subject { -> { request.get("/", "HTTP_IDEMPOTENCY_KEY" => 'x') } }

    it { is_expected.to raise_error(Rack::Idempotency::InsecureKeyError) }
  end

  context "with an idempotency key" do
    subject { request.get("/", "HTTP_IDEMPOTENCY_KEY" => key).body }

    context "with a successful request" do
      context "on first request" do
        it { is_expected.to_not be_nil }
      end

      context "on second request" do
        let(:original) { request.get("/", "HTTP_IDEMPOTENCY_KEY" => key).body }

        it { is_expected.to eq(original) }
      end

      context "on different request" do
        let(:different) { request.get("/", "HTTP_IDEMPOTENCY_KEY" => SecureRandom.uuid).body }

        it { is_expected.to_not eq(different) }
      end
    end

    context "with a failed request" do
      let(:app) { lambda { |_| [500, { "Content-Type" => "text/plain" }, [SecureRandom.uuid]] } }

      context "on first request" do
        it { is_expected.to_not be_nil }
      end

      context "on second request" do
        let(:original) { request.get("/", "HTTP_IDEMPOTENCY_KEY" => key).body }

        it { is_expected.to_not eq(original) }
      end
    end
  end
end
