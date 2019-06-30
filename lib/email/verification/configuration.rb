module Email
  module Verification
    class Configuration
      attr_accessor :verbose
      
      def initialize
        self.verbose = false
      end
      
    end
  end
end
