# frozen_string_literal: true

require 'forget_that/version'
require 'forget_that/service'
require 'forget_that/record'

module ForgetThat
  class InvalidConfigError < StandardError; end
  class InvalidCollectionError < StandardError; end

  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = name
      end
    end
  end
end
