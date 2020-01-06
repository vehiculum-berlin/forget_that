# frozen_string_literal: true

require 'rails/generators/active_record'

module ForgetThat
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, 'templates')

      def copy_migration
        migration_template 'migration.rb', 'db/migrate/install_forget_that.rb', migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def used_tables
        YAML
          .load_file('config/anonymization_config.yml')
          .dig('schema')
          .keys
          .map { |table| [table, ActiveRecord::Base.connection.columns(table).map(&:name).include?('anonymized')] }
          .to_h
          .reject { |_key, value| value }
          .keys
      end
    end
  end
end
