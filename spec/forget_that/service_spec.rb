# frozen_string_literal: true

require_relative './helpers/schema_helper.rb'

RSpec.describe ForgetThat::Service do
  include SchemaHelper

  TABLE_DATA_FAIL = {
    data: {
      bank_accounts: {
        bic: { type: 'string', name: 'bic' },
        iban: { type: 'string', name: 'iban' },
        bank_name: { type: 'string', name: 'bank_name' },
        created_at: { type: 'datetime', name: 'created_at' },
        updated_at: { type: 'datetime', name: 'updated_at' }
      },
      addresses: {
        city: { type: 'string', name: 'city' },
        zip_code: { type: 'string', name: 'zip_code' },
        street: { type: 'string', name: 'street' },
        street_number: { type: 'string', name: 'street_number' },
        lived_since: { type: 'date', name: 'lived_since' },
        created_at: { type: 'datetime', name: 'created_at' },
        updated_at: { type: 'datetime', name: 'updated_at' },
        anonimyzed: { type: 'boolean', name: 'anonymized' }
      }
    }
  }.freeze
  TABLE_DATA_SUCCESS = TABLE_DATA_FAIL.deep_dup
  TABLE_DATA_SUCCESS[:data][:bank_accounts][:anonymized] = { type: 'boolean', name: 'anonymized' }

  before do
    SchemaHelper.define_schema(TABLE_DATA_SUCCESS)
  end

  describe 'initialize' do
    context 'succsessfull initialization' do
      it do
        expect { ForgetThat::Service.new }.not_to raise_error
      end
    end
  end

  describe 'anonymizers' do
    it 'returns the list of anonymizers' do
      expect(ForgetThat::Service.new.anonymizers.keys).to eq(
        %i[random_date hex_string random_phone fake_personal_id_number random_amount]
      )
    end
  end

  describe 'valid_config?' do
    context 'config is valid' do
      it do
        expect(ForgetThat::Service.new.valid_config?).to eq(true)
      end
    end
  end

  describe 'valid_anonymizer_set?' do
    context 'anonymizer set is matching' do
      it do
        expect(ForgetThat::Service.new.valid_anonymizer_set?).to eq(true)
      end
    end
  end

  describe 'valid_database_schema?' do
    context 'when valid' do
      it 'tables contain necessary columns' do
        expect(ForgetThat::Service.new.valid_database_schema?).to eq(true)
      end
    end

    context 'when not valid' do
      it 'some tables do not contain necessary columns' do
        SchemaHelper.define_schema(TABLE_DATA_FAIL)
        expect(ForgetThat::Service.new.valid_database_schema?).to eq(false)
      end
    end
  end

  describe 'sanitize_collection' do
    it 'returns anonymized collection' do
      table_data = {
        data: {
          addresses: {
            city: { type: 'string', name: 'city' },
            zip_code: { type: 'string', name: 'zip_code' },
            street: { type: 'string', name: 'street' },
            street_number: { type: 'string', name: 'street_number' },
            lived_since: { type: 'string', name: 'lived_since' },
            foo: { type: 'string', name: 'foo' }
          }
        }
      }

      SchemaHelper.define_schema(table_data)
      Address = Class.new(ActiveRecord::Base) { self.table_name = 'addresses' }

      Address.create(
        city: 'A',
        zip_code: 'B',
        street: 'D',
        street_number: '45',
        lived_since: Time.parse('2019-10-05 18:20:00').utc,
        foo: 'bar'
      )

      Address.create(
        city: 'Aa',
        zip_code: 'Ba',
        street: 'Da',
        street_number: '45a',
        lived_since: Time.parse('2019-10-05 18:20:00').utc,
        foo: 'bard'
      )

      sanitized_data = ForgetThat::Service.new.sanitize_collection(Address.all)

      expect(sanitized_data.count).to eq(2)
      expect(sanitized_data.first['city']).to eq('Kyteż')
      expect(sanitized_data.last['city']).to eq('Kyteż')
      expect(sanitized_data.first['street']).to eq('Sesame Street')
      expect(sanitized_data.last['street']).to eq('Sesame Street')
      expect(sanitized_data.first['lived_since']).not_to eq(Time.parse('2019-10-05 18:20:00').utc)
      expect(sanitized_data.last['lived_since']).not_to eq(Time.parse('2019-10-05 18:20:00').utc)
      expect(sanitized_data.first['foo']).to eq('bar')
      expect(sanitized_data.last['foo']).to eq('bard')
    end
  end
end
