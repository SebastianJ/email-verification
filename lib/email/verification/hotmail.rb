module Email
  module Verification
    class Hotmail < Base
      
      def retrieve_verification_code(email:, password:, mailboxes: %w(Inbox Junk), count: :all, settings: {}, proxy: nil)
        super(email: email, password: password, host: "outlook.office365.com", port: 993, enable_ssl: true, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy)
      end
      
    end
  end
end
