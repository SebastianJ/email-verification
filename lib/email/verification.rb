require "gmail"
require "mail"
require "yaml"

require "email/verification/version"

require "email/verification/configuration"

require "email/verification/errors"

require "email/verification/base"
require "email/verification/gmail"
require "email/verification/hotmail"

require "email/verification/verifier"

module Email
  module Verification
    class Error < StandardError; end
    
    class << self
      attr_writer :configuration
    end
    
    def self.configuration
      @configuration  ||=   ::Email::Verification::Configuration.new
    end

    def self.reset
      @configuration    =   ::Email::Verification::Configuration.new
    end

    def self.configure
      yield(configuration)
    end
    
    def self.retrieve_verification_code(email:, password:, mailboxes: %w(Inbox), settings: {})
      ::Email::Verification::Verifier.new.retrieve_verification_code(email: email, password: password, mailboxes: mailboxes, settings: settings)
    end
    
  end
end
