require 'boucher/compute'

module Boucher

  module SecurityGroups
    SECURITY_GROUP_TABLE_FORMAT = "%-12s  %-12s  %-10s  %-50s\n"

    module Printing
      def self.print_table(security_groups, servers_for_groups)
        printf SECURITY_GROUP_TABLE_FORMAT, "ID", "Name", "Environment", "Servers"
        puts
        security_groups.each do |security_group|
          printf SECURITY_GROUP_TABLE_FORMAT,
            security_group.group_id,
            security_group.name,
            "????",
            servers_for_groups[security_group.name].map(&:id)
        end
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
