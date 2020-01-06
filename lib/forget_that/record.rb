# frozen_string_literal: true

require 'active_record'
module ForgetThat
  class Record < ActiveRecord::Base
    retention_threshold = (
      ->                    { YAML.load_file('config/anonymization_config.yml') } >>
      ->(config)            { config.dig('config', 'retention_time') } >>
      ->(retention_params)  { retention_params['value'].send(retention_params['unit']) } >>
      ->(retention_time)    { Time.current - retention_time }
    )

    scope :for_anonymization, (lambda do
      where(anonymized: false)
        .where('created_at < ?', retention_threshold.call)
    end)
  end
end
