# frozen_string_literal: true

module ForgetThat
  class Service
    def initialize(options = {})
      @custom_anonymizers = options[:anonymizers] || {}
    end

    def call
      raise InvalidConfigError unless valid_config?

      config.each do |table, columns|
        klass = Class.new(ForgetThat::Record) { self.table_name = table }
        records_hash = klass
                       .for_anonymization
                       .pluck(:id)
                       .map { |id| [id, populate_records_hash(columns)] }
                       .to_h
        klass.update(records_hash.keys, records_hash.values)
      end
    end

    def anonymizers
      {
        random_date: -> { Time.now - [*1..10**4].sample.days },
        hex_string: -> { SecureRandom.hex(5) },
        random_phone: -> { "+49#{[*0..10].map { SecureRandom.random_number(10) } .join}" },
        fake_personal_id_number: -> { "DE#{[*0..10].map { SecureRandom.random_number(10) }.join}" },
        random_amount: -> { [*1..80].sample * [*900..1100].sample }
      }.merge(@custom_anonymizers)
    end

    def valid_config?
      return false unless valid_anonymizer_set?
      return false unless valid_database_schema?

      true
    end

    def valid_anonymizer_set?
      available = anonymizers.stringify_keys.keys
      required = config
                 .map { |_key, value| value.map { |_key, val| val } }
                 .flatten
                 .map { |value| value.to_s.scan(/%{(\w*)\.?.*}/) }
                 .flatten
                 .uniq
      return true if (required - available).empty?

      ForgetThat.logger.error("Anonymizers #{(required - available).join(', ')} are not defined")
      false
    end

    def valid_database_schema?
      if config
         .keys
         .map { |table| ActiveRecord::Base.connection.columns(table).map(&:name).include? 'anonymized' }
         .reduce { |a, b| a && b }
        true
      else
        ForgetThat.logger.error('Some of the tables in your database do not contain `anonymized` flag')
        false
      end
    end

    private

    def populate_records_hash(columns)
      columns
        .map { |key, value| [key, value.to_s % generate_anonymized_values] }
        .to_h
        .merge('anonymized' => true)
    end

    def generate_anonymized_values
      anonymizers.map { |key, value| [key, value.call] }.to_h
    end

    def config
      YAML.load_file('config/anonymization_config.yml').dig('schema')
    end
  end
end
