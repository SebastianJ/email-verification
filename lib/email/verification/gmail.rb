module Email
  module Verification
    class Gmail < Base
      
      def retrieve_verification_code(email:, password:, mark_as_read: true, mailboxes: [], settings: {})
        emails    =   []
        result    =   nil
    
        begin
          args    =   settings_provided?(settings) ? {from: settings[:address]} : {}
          
          ::Gmail.connect(email, password) do |gmail|
            gmail.inbox.emails(args).each do |email|
              log("Email - from: #{email.from.first.name}, subject: #{email.subject}")
              
              if settings_provided?(settings)
                matching_name       =   settings[:from].to_s.empty? || (!settings[:from].to_s.empty? && email.from.first.name == settings[:from])
                matching_subject    =   settings[:subject].nil?     || (!settings[:subject].nil? && email.subject =~ settings[:subject])
                
                if matching_name && matching_subject
                  emails  <<  (email.html_part || email.text_part || email).body.decoded
                  email.read! if mark_as_read
                end
              else
                emails    <<  (email.html_part || email.text_part || email).body.decoded
                email.read! if mark_as_read
              end
            end
          end
        
        rescue Net::IMAP::BadResponseError => e
          raise ArgumentError, "You need to enable logins for less secure apps in Gmail for #{email}!"
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
