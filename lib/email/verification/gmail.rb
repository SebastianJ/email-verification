module Email
  module Verification
    class Gmail < Base
      
      def retrieve_verification_code(email:, password:, mark_as_read: true, count: :all, mailboxes: %w(Inbox), settings: {}, proxy: nil)
        if proxy && !proxy.empty? && !proxy[:host].to_s.empty? && !proxy[:port].to_s.empty?
          return super(email: email, password: password, host: "imap.gmail.com", port: 993, enable_ssl: true, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy)
        else
          return normal_retrieve_verification_code(email: email, password: password, mark_as_read: mark_as_read, count: count, mailboxes: mailboxes, settings: settings)
        end
      end
      
      def normal_retrieve_verification_code(email:, password:, mark_as_read: true, count: :all, mailboxes: %w(Inbox), settings: {})
        emails    =   []
        result    =   nil
    
        begin
          args    =   settings_provided?(settings) ? {from: settings[:address]} : {}
          
          ::Gmail.connect(email, password) do |gmail|
            gmail.inbox.emails(args).each do |email|
              log("Email - from: #{email.from.first.name}, subject: #{email.subject}")
              
              if settings_provided?(settings)
                matching_name       =   settings[:from].to_s.empty? || (!settings[:from].to_s.empty? && email.from.first.name == settings[:from])
                matching_subject    =   settings[:subject].nil?     || (!settings[:subject].nil? && !(email.subject =~ settings[:subject]).nil?)
                
                emails  <<  email_body(email) if matching_name && matching_subject
              else
                emails  <<  email_body(email)
              end
              
              email.read! if mark_as_read
            end
          end
        
        rescue Net::IMAP::BadResponseError => e
          raise ::Email::Verification::Errors::InvalidCredentialsError.new("You need to enable logins for less secure apps in Gmail for #{email}!")
        end
        
        if settings_provided?(settings)
          message     =   emails.last&.to_s
          result      =   message&.match(settings[:regex])&.[](:match)
        else
          result      =   emails
        end
        
        return result
      end
      
    end
  end
end
