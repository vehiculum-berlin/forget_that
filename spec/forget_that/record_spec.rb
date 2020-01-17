# frozen_string_literal: true

require 'active_support/time'

RSpec.describe ForgetThat::Record do
  context 'scope for_anonymization' do
    table_data = {
      data: {
        banks: {
          name: { type: 'string', name: 'name', constraints: { null: false } },
          created_at: { type: 'datetime', name: 'created_at', constraints: { null: false } },
          updated_at: { type: 'datetime', name: 'updated_at', constraints: { null: false } },
          anonymized: { type: 'boolean', name: 'anonymized', constraints: { dafeult: false } }
        }
      }
    }

    before do
      allow(Time).to receive(:current) { Time.parse('2019-10-05 18:20:00').utc }
    end

    describe 'success' do
      it do
        SchemaHelper.define_schema(table_data)

        klass = Class.new(ForgetThat::Record) { self.table_name = 'banks' }
        expect(
          klass
            .for_anonymization
            .to_sql
            .match(/SELECT \"banks\".*\s?FROM\s?\"banks\"\s?WHERE\s?\"banks\".\"anonymized\"\s?=\s?0\s?AND\s?\(created_at\s?<\s?'(.*)'\)/)[1]
            .concat(' UTC')
            .to_time
        ).to eq(Time.current - 90.days)
      end
    end
  end
end
