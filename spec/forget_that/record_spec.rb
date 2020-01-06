# frozen_string_literal: true

# require 'components/shared/spec_helper'
require 'active_support/time'

RSpec.describe ForgetThat::Record do
  describe 'scope for_anonymization' do
    before do
      allow(Time).to receive(:current) { Time.parse('2019-10-05 18:20:00').utc }
    end
    it do
      ActiveRecord::Base.establish_connection(adapter: 'postgresql')
      ActiveRecord::Schema.define do
        self.verbose = false

        create_table 'banks', force: :cascade do |t|
          t.string 'name', null: false
          t.datetime 'created_at', null: false
          t.datetime 'updated_at', null: false
          t.boolean 'anonymized', default: false
        end
      end

      klass = Class.new(ForgetThat::Record) { self.table_name = 'banks' }
      expect(
        klass
          .for_anonymization
          .to_sql
          .match(/SELECT \"banks\".*\s?FROM\s?\"banks\"\s?WHERE\s?\"banks\".\"anonymized\"\s?=\s?FALSE\s?AND\s?\(created_at\s?<\s?'(.*)'\)/)[1]
          .concat(' UTC')
          .to_time
      ).to eq(Time.current - 90.days)
    end
  end
end
