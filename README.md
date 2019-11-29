# PdEventV2

[PagerDuty Events API v2](https://v2.developer.pagerduty.com/docs/events-api-v2) Ruby Client.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pd_event_v2'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pd_event_v2

## Usage

```ruby
require 'pd_event_v2'

# routing_key: Integration Key
client = PdEventV2::Client.new(routing_key: 'ZAPZAPZAP')

# see https://v2.developer.pagerduty.com/v2/docs/send-an-event-events-api-v2
res = client.trigger(
  payload: {
    summary: 'Example alert on host1.example.com',
    source: 'monitoringtool:cloudvendor:central-region-dc-01:852559987:cluster/api-stats-prod-003',
    severity: 'info'
  }
)

p res #=> {
      #     'status' => 'success',
      #     'message' => 'Event processed',
      #     'dedup_key' => '3c053fc438cc4608b8382b28adc0af8d'
      #   }
```
