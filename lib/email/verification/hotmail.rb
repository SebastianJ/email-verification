module Email
  module Verification
    class Hotmail < Base
      
      def retrieve_verification_code(email:, password:, mailboxes: %w(Inbox Junk), settings: {})
        super(email: email, password: password, host: "outlook.office365.com", port: 993, enable_ssl: true, mailboxes: mailboxes, settings: settings)
      end
      
    end
  end
end
