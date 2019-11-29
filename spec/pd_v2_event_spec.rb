# frozen_string_literal: true

RSpec.describe PdEventV2::Client do
  let(:routing_key) { 'ZAPZAPZAP' }
  let(:dedup_key) { 'samplekeyhere' }

  let(:payload) do
    {
      'summary' => 'Example alert on host1.example.com',
      'timestamp' => '2015-07-17T08:42:58.315+0000',
      'source' => 'monitoringtool:cloudvendor:central-region-dc-01:852559987:cluster/api-stats-prod-003',
      'severity' => 'info',
      'component' => 'postgres',
      'group' => 'prod-datapipe',
      'class' => 'deploy',
      'custom_details' => {
        'ping time' => '1500ms',
        'load avg' => 0.75,
      },
    }
  end

  let(:images) do
    [{
      'src' => 'https://www.pagerduty.com/wp-content/uploads/2016/05/pagerduty-logo-green.png',
      'href' => 'https://example.com/',
      'alt' => 'Example text',
    }]
  end

  let(:links) do
    [{
      'href' => 'https://example.com/',
      'text' => 'Link text',
    }]
  end

  let(:trigger_client) { 'Sample Monitoring Service' }
  let(:client_url) { 'https://monitoring.example.com' }

  let(:res_body) do
    {
      'status' => 'success',
      'message' => 'Event processed',
      'dedup_key' => '3c053fc438cc4608b8382b28adc0af8d',
    }
  end

  let(:options) { { routing_key: routing_key } }

  let(:client) do
    described_class.new(options) do |faraday|
      faraday.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/v2/enqueue') do |env|
          body = JSON.parse(env.body)
          expect(body).to eq expected_req_body
          [202, { 'Content-Type' => 'application/json' }, JSON.dump(res_body)]
        end
      end
    end
  end

  let(:expected_req_body) do
    {
      'event_action' => event_action,
      'routing_key' => routing_key,
      'dedup_key' => dedup_key,
      'payload' => payload,
      'images' => images,
      'links' => links,
      'client' => trigger_client,
      'client_url' => client_url,
    }
  end

  context 'when trigger' do
    let(:event_action) { 'trigger' }

    specify do
      res = client.trigger(
        dedup_key: dedup_key,
        payload: payload,
        images: images,
        links: links,
        client: trigger_client,
        client_url: client_url
      )

      expect(res).to eq(res_body)
    end
  end

  context 'when acknowledge' do
    let(:event_action) { 'acknowledge' }

    specify do
      res = client.acknowledge(
        dedup_key: dedup_key,
        payload: payload,
        images: images,
        links: links,
        client: trigger_client,
        client_url: client_url
      )

      expect(res).to eq(res_body)
    end
  end

  context 'when resolve' do
    let(:event_action) { 'resolve' }

    specify do
      res = client.resolve(
        dedup_key: dedup_key,
        payload: payload,
        images: images,
        links: links,
        client: trigger_client,
        client_url: client_url
      )

      expect(res).to eq(res_body)
    end
  end

  context 'when missing payload' do
    specify do
      expect do
        client.trigger
      end.to raise_error(/missing keyword: payload/)
    end
  end

  context 'when missing required payload key' do
    specify do
      expect do
        client.trigger(payload: {})
      end.to raise_error(/missing payload key:/)
    end
  end

  context 'when extra keys are passed' do
    specify do
      expect do
        client.trigger(payload: payload.merge(extra_key: 'extra'))
      end.to raise_error('invalid payload keys: [:extra_key]')
    end
  end
end
