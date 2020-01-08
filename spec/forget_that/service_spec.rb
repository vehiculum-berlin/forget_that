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
end
