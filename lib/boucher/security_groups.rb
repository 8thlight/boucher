require 'boucher/compute'

module Boucher

  module SecurityGroups

    module Printing
      def print_table(security_groups)
        #p "HELLO"
      end
    end

    class << self
      def all
        Boucher.compute.security_groups
      end

      def servers_for_groups
        all.reduce({}) do |memo, current|
          memo[current.name] = Boucher::Servers.with_group(current.name)
          memo
        end
      end
    end
  end
end
