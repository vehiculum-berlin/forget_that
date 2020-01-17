# frozen_string_literal: true

module SchemaHelper
  def self.define_schema(table_data)
    ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

    ActiveRecord::Schema.define do
      self.verbose = false

      data = table_data[:data]

      data.each do |table_name, columns|
        create_table table_name.to_s, force: :cascade do |t|
          columns.each do |_key, attrs|
            case attrs[:constraints]
            when attrs[:constraints].blank?
              t.public_send(attrs[:type], attrs[:name])
            else
              t.public_send(attrs[:type], attrs[:name], attrs[:constraints].symbolize_keys)
            end
          end
        end
      end
    end
  end
end
