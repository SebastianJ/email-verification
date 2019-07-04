module Email
  module Verification
    class Verifier
      attr_accessor :mapping
      
      def initialize
        set_mapping
      end
      
      def set_mapping
        mappings_path         =   File.join(File.dirname(__FILE__), "data/domains.yml")
        
        if ::File.exists?(mappings_path)
          self.mapping        =   YAML.load_file(mappings_path)
        end
      end
      
      def retrieve_verification_code(email:, password:, mailboxes: %w(Inbox), count: :all, settings: {}, wait: 3, retries: 3)
        result        =   nil
        service       =   determine_email_service(email)
        
        verifier      =   case service
          when :gmail
            ::Email::Verification::Gmail.new
          when :hotmail
            ::Email::Verification::Hotmail.new
          else
            nil
        end
        
        if verifier
          if settings_provided?(settings) && !wait.nil? && !retries.nil?
            result    =   retrieve_with_retries(verifier, email: email, password: password, mailboxes: mailboxes, count: count, settings: settings, wait: wait, retries: retries)
          else
            result    =   verifier.retrieve_verification_code(email: email, password: password, mailboxes: mailboxes, count: count, settings: settings)
          end
        end
        
        return result
      end
      
      def retrieve_with_retries(verifier, email:, password:, mailboxes: %w(Inbox), count: :all, settings: {}, wait: 3, retries: 3)
        result        =   nil
        
        begin
          result      =   verifier.retrieve_verification_code(email: email, password: password, mailboxes: mailboxes, count: count, settings: settings)
          
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
      
    end
  end
end
