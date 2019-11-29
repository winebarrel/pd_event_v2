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

  context 'when trigger' do
    let(:expected_req_body) do
      {
        'event_action' => 'trigger',
        'routing_key' => routing_key,
        'dedup_key' => dedup_key,
        'payload' => payload,
        'images' => images,
        'links' => links,
      }
    end

    specify 'has a version number' do
      res = client.trigger(
        dedup_key: dedup_key,
        payload: payload,
        images: images,
        links: links
      )

      expect(res).to eq(res_body)
    end
  end

  context 'when acknowledge' do
    let(:expected_req_body) do
      {
        'event_action' => 'acknowledge',
        'routing_key' => routing_key,
        'dedup_key' => dedup_key,
        'payload' => payload,
        'images' => images,
        'links' => links,
      }
    end

    specify 'has a version number' do
      res = client.acknowledge(
        dedup_key: dedup_key,
        payload: payload,
        images: images,
        links: links
      )

      expect(res).to eq(res_body)
    end
  end

  context 'when resolve' do
    let(:expected_req_body) do
      {
        'event_action' => 'resolve',
        'routing_key' => routing_key,
        'dedup_key' => dedup_key,
        'payload' => payload,
        'images' => images,
        'links' => links,
      }
    end

    specify 'has a version number' do
      res = client.resolve(
        dedup_key: dedup_key,
        payload: payload,
        images: images,
        links: links
      )

      expect(res).to eq(res_body)
    end
  end
end
