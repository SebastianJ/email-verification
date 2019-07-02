module Email
  module Verification
    class Base
      attr_accessor :configuration
      
      def initialize(configuration: ::Email::Verification.configuration)
        self.configuration      =     configuration
      end
      
      def retrieve_verification_code(email:, password:, host:, port: 993, enable_ssl: true, mailboxes: %w(Inbox), settings: {})
        emails    =   []
        result    =   nil
        
        begin
          Mail.defaults do                      
            retriever_method :imap, address:    host,
                                    port:       port,
                                    user_name:  email,
                                    password:   password,
                                    enable_ssl: enable_ssl
          end
        
          mailboxes.each do |mailbox|
            Mail.find(mailbox: mailbox, order: :desc)&.each do |email|
              log("From: #{email.from&.first&.strip}. Subject: #{email.subject}")
              
              if settings_provided?(settings)
                matching_subject    =   settings[:subject].nil? || (!settings[:subject].nil? && email.subject =~ settings[:subject])
                
                emails  <<  email_body(email) if email.from&.first&.strip == settings[:address] && matching_subject
              else
                emails  <<  email_body(email)
              end
            end
          end
          
        rescue Net::IMAP::NoResponseError => e
          raise ArgumentError, "Please check account/password settings for email #{email}!"
        end
        
        if settings_provided?(settings)
          message   =   emails&.first
          code      =   message&.match(settings[:regex])&.[](:match)
        else
          result    =   emails
        end
        
        return result
      end
      
      def settings_provided?(settings = {})
        settings && !settings.empty?
      end
      
      def email_body(email)
        body        =   (email.html_part || email.text_part || email)&.body&.decoded
        force_utf8(body)
      end
      
      def force_utf8(string)
        string&.encode("UTF-8", invalid: :replace, undef: :replace, replace: '')&.force_encoding('UTF-8')
      end
      
      def log(message)
        puts "[Email::Verification] - #{Time.now.to_s}: #{message}" if self.configuration.verbose
      end
      
    end
  end
end
