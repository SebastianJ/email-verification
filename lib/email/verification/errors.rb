module Email
  module Verification
    module Errors
      
      class Error < StandardError; end
      class InvalidCredentialsError < Email::Verification::Errors::Error; end
      class ImapNotSupportedError < Email::Verification::Errors::Error; end
      
    end
  end
end
