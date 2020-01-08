# frozen_string_literal: true

RSpec.describe ForgetThat::Service do
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
        ActiveRecord::Base.establish_connection(adapter: 'postgresql')
        ActiveRecord::Schema.define do
          self.verbose = false

          create_table 'addresses', force: :cascade do |t|
            t.string 'city'
            t.string 'zip_code'
            t.string 'street'
            t.string 'street_number'
            t.date 'lived_since'
            t.datetime 'created_at', null: false
            t.datetime 'updated_at', null: false
            t.boolean 'anonymized', default: false
          end

          create_table 'bank_accounts', force: :cascade do |t|
            t.string 'bic'
            t.string 'iban'
            t.string 'bank_name'
            t.datetime 'created_at', null: false
            t.datetime 'updated_at', null: false
            t.boolean 'anonymized', default: false
          end
        end
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
    context 'tables contain necessary columns' do
      it do
        ActiveRecord::Base.establish_connection(adapter: 'postgresql')
        ActiveRecord::Schema.define do
          self.verbose = false

          create_table 'addresses', force: :cascade do |t|
            t.string 'city'
            t.string 'zip_code'
            t.string 'street'
            t.string 'street_number'
            t.date 'lived_since'
            t.datetime 'created_at', null: false
            t.datetime 'updated_at', null: false
            t.boolean 'anonymized', default: false
          end

          create_table 'bank_accounts', force: :cascade do |t|
            t.string 'bic'
            t.string 'iban'
            t.string 'bank_name'
            t.datetime 'created_at', null: false
            t.datetime 'updated_at', null: false
            t.boolean 'anonymized', default: false
          end
        end
        expect(ForgetThat::Service.new.valid_database_schema?).to eq(true)
      end
    end

    context 'some tables do not contain necessary columns' do
      it do
        ActiveRecord::Base.establish_connection(adapter: 'postgresql')
        ActiveRecord::Schema.define do
          self.verbose = false

          create_table 'addresses', force: :cascade do |t|
            t.string 'city'
            t.string 'zip_code'
            t.string 'street'
            t.string 'street_number'
            t.date 'lived_since'
            t.datetime 'created_at', null: false
            t.datetime 'updated_at', null: false
            t.boolean 'anonymized', default: false
          end

          create_table 'bank_accounts', force: :cascade do |t|
            t.string 'bic'
            t.string 'iban'
            t.string 'bank_name'
            t.datetime 'created_at', null: false
            t.datetime 'updated_at', null: false
          end
        end
        expect(ForgetThat::Service.new.valid_database_schema?).to eq(false)
      end
    end
  end

  describe 'sanitize_collection' do
    it 'returns anonymized collection' do
      ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

      ActiveRecord::Schema.define do
        self.verbose = false

        create_table 'addresses', force: :cascade do |t|
          t.string 'city'
          t.string 'zip_code'
          t.string 'street'
          t.string 'street_number'
          t.date 'lived_since'
          t.string 'foo'
        end
      end

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
