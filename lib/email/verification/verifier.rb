module Email
  module Verification
    class Verifier
      attr_accessor :mapping, :mode, :cli
      
      def initialize(mode: :interactive)
        self.mode             =   mode&.to_sym
        self.cli              =   self.mode.eql?(:interactive) ? ::HighLine.new : nil
        
        set_mapping
      end
      
      def set_mapping
        mappings_path         =   File.join(File.dirname(__FILE__), "data/domains.yml")
        
        if ::File.exists?(mappings_path)
          self.mapping        =   YAML.load_file(mappings_path)
        end
      end
      
      def retrieve_verification_code(email:, password:, mailboxes: %w(Inbox), count: :all, settings: {}, proxy: nil, wait: 3, retries: 3)
        service       =   determine_email_service(email)
        result        =   nil
        
        begin
          result      =   case service
            when :gmail
              perform_retrieval(::Email::Verification::Gmail.new, email: email, password: password, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy, wait: wait, retries: retries)
            when :hotmail
              perform_retrieval(::Email::Verification::Hotmail.new, email: email, password: password, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy, wait: wait, retries: retries)
            when :protonmail, :tutanota
              if self.mode.eql?(:interactive)
                puts "[Email::Verification::Verifier] - #{Time.now}: You're using an email account that doesn't have support for POP3 or IMAP. You have to manually retrieve the code or URL from the account and post it below."
                capture_cli_input(email)
              else
                raise ::Email::Verification::Errors::ImapNotSupportedError.new("#{service} doesn't have support for IMAP or POP3 retrieval! Please switch to interactive mode or use another provider!")
              end
            else
              nil
          end
        
        rescue Net::HTTPClientException => e
          raise ::Email::Verification::Errors::InvalidProxyError.new("Proxy isn't working, please retry with a new proxy!")
        end
        
        return result
      end
      
      def perform_retrieval(verifier, email:, password: nil, mailboxes: %w(Inbox), count: :all, settings: {}, proxy: nil, wait: 3, retries: 3)
        result        =   nil
        
        if password.to_s.empty? && self.mode.eql?(:interactive)
          puts "[Email::Verification::Verifier] - #{Time.now}: Password wasn't provided, you need to manually retrieve the code or URL from the account #{email}."
          result      =   capture_cli_input(email)
        elsif password.to_s.empty? && self.mode.eql?(:automatic)
          raise ::Email::Verification::Errors::InvalidCredentialsError.new("Password wasn't provided for #{email} and automatic mode is enabled. Please provide a password or switch to interactive mode.")
        else
          if settings_provided?(settings) && !wait.nil? && !retries.nil?
            result    =   retrieve_with_retries(verifier, email: email, password: password, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy, wait: wait, retries: retries)
          else
            result    =   verifier.retrieve_verification_code(email: email, password: password, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy)
          end
        end
        
        return result
      end
      
      def retrieve_with_retries(verifier, email:, password: nil, mailboxes: %w(Inbox), count: :all, settings: {}, proxy: nil, wait: 3, retries: 3)
        result        =   nil
        
        begin
          result      =   verifier.retrieve_verification_code(email: email, password: password, mailboxes: mailboxes, count: count, settings: settings, proxy: proxy)
          
          if result.to_s.empty?
            sleep wait if wait
            retries  -=  1
          end
        end while result.to_s.empty? && retries > 0
        
        return result
      end
      
      def determine_email_service(email_address)
        email_domain              =   email_address&.split('@')&.last&.strip
        
        detected_service          =   catch(:service_detection) do
          self.mapping.each do |service, domains|
            if domains.include?(email_domain)
              detected_service    =   service.to_sym
              throw :service_detection, detected_service
            end
          end unless email_domain.to_s.empty?
        end
        
        return detected_service
      end
      
      def settings_provided?(settings = {})
        settings && !settings.empty?
      end
      
      def capture_cli_input(email)
        self.cli.ask("Please enter the code or URL sent to #{email}:")&.strip
      end
      
    end
  end
end
