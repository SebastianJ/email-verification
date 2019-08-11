module Email
  module Verification
    class Base
      attr_accessor :configuration
      
      def initialize(configuration: ::Email::Verification.configuration)
        self.configuration      =     configuration
      end
      
      def set_retriever(email:, password:, host:, port: 993, enable_ssl: true, proxy: nil)
        retriever               =   :imap
        
        options                 =   {
          address:    host,
          port:       port,
          user_name:  email,
          password:   password,
          enable_ssl: enable_ssl
        }
        
        if proxy && !proxy.empty? && !proxy[:host].to_s.empty? && !proxy[:port].to_s.empty?
          retriever             =   ::Net::IMAP::Proxy::RetrieverMethod
          proxy[:host]          =   "http://#{proxy[:host]}" unless proxy[:host] =~ /^http(s)?:\/\//i
          options               =   options.merge(proxy_address: proxy[:host], proxy_port: proxy[:port])
          log("Will use proxy #{proxy[:host]}:#{proxy[:port]} to fetch messages from #{options[:address]}:#{options[:port]}")
        end
        
        Mail.defaults do                      
          retriever_method retriever, options
        end
      end
      
      def retrieve_verification_code(email:, password:, host:, port: 993, enable_ssl: true, count: :all, mailboxes: %w(Inbox), settings: {}, proxy: nil)
        emails    =   []
        result    =   nil
        
        begin
          set_retriever(email: email, password: password, host: host, port: port, enable_ssl: enable_ssl, proxy: proxy)
          
          mailboxes.each do |mailbox|
            Mail.find(mailbox: mailbox, order: :desc, count: count)&.each do |email|
              log("From: #{email.from&.first&.strip}. Subject: #{email.subject}")
              
              if settings_provided?(settings)
                matching_address    =   email.from&.first&.strip == settings[:address]
                matching_subject    =   settings[:subject].nil? || (!settings[:subject].nil? && !(email.subject =~ settings[:subject]).nil?)
                
                emails  <<  email_body(email) if matching_address && matching_subject
              else
                emails  <<  email_body(email)
              end
            end
          end
          
        rescue Net::IMAP::NoResponseError => e
          raise ::Email::Verification::Errors::InvalidCredentialsError.new("Please check account/password settings for email #{email}!")
        end
        
        if settings_provided?(settings)
          message   =   emails.first&.to_s
          result    =   message&.match(settings[:regex])&.[](:match)
        else
          result    =   emails
        end
        
        return result
      end
      
      def settings_provided?(settings = {})
        settings && !settings.empty?
      end
      
      def email_body(email)
        body        =   (email.html_part || email.text_part || email)&.body
        
        begin
          body      =   body&.decoded
        rescue Mail::UnknownEncodingType
          body      =   body&.encoded
        end
        
        body        =   force_utf8(body) unless body.to_s.empty?
        
        return body
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
