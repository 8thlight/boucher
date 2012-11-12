require 'boucher/compute'
require 'boucher/servers'

module Boucher
  module SecurityGroups
    SECURITY_GROUP_TABLE_FORMAT = "%-12s  %-12s  %-50s\n"
    RULE_WIDTH = 18
    RULE_TABLE_FORMAT = "%-#{RULE_WIDTH}s  %-19s  %-10s %-10s %-10s\n"

    module Printing
      def self.print_table(security_groups, servers_for_groups)
        puts "----------------------------------------------------------------------"
        security_groups.each do |security_group|
          puts "GROUP:"
          printf SECURITY_GROUP_TABLE_FORMAT, "ID", "Name", "Servers"
          printf SECURITY_GROUP_TABLE_FORMAT,
            security_group.group_id,
            security_group.name,
            server_names(servers_for_groups[security_group.name])
          puts "\n"
          puts "RULES FOR GROUP:"
          printf RULE_TABLE_FORMAT, "Incoming Groups", "Incoming IP", "Protocol", "Min Port", "Max Port"
          security_group.ip_permissions.each do |rule|
            printf RULE_TABLE_FORMAT, rule_groups(rule), rule_ip(rule), rule["ipProtocol"], rule["fromPort"], rule["toPort"]
          end
          puts "----------------------------------------------------------------------"
          puts "\n"
        end
      end
      def self.rule_groups(ip_permissions)
        names = ip_permissions["groups"].map do |group|
          group["groupName"].ljust(RULE_WIDTH)
        end
        if names.empty?
          "______"
        else
          names.join("\n")
        end
      end

      def self.rule_ip(ip_permission)
        ip = (ip_permission["ipRanges"].first || {})["cidrIp"]
        ip || "______"


      end


      def self.server_names(servers)
        servers.map { |server|
          "#{server.id}(#{server.tags['Meal']})"
        }.join(', ')
      end
    end

    class << self
      def all
        Boucher.compute.security_groups
      end

      def transform_ip(ip)
        appendix = (ip == "0.0.0.0") ? 0 : 32
        "#{ip}/#{appendix}"
      end

      def colliding_configuration(configuration)
        all.get(configuration[:name])
      end

      def build_for_configuration(configuration)
        destroy_existing_configuration(configuration)
        group = all.new(
          name: configuration[:name],
          description: configuration[:description]
        )
        group.save
        group
      end

      def destroy_existing_configuration(configuration)
        existing_configuration = all.get(configuration[:name])
        existing_configuration.destroy if existing_configuration
      end

      def authorize(group, permission)
        range = (permission[:from_port]..permission[:to_port])
        ip = transform_ip(permission[:incoming_ip]) if permission[:incoming_ip]
        options = {
          cidr_ip: ip,
          group: permission[:group],
          ip_protocol: permission[:ip_protocol]
        }
        group.authorize_port_range(range, compact_hash(options))
      end

      def compact_hash(to_compact)
        to_compact.reject do |key|
          to_compact[key].nil?
        end
      end

      def build_for_configurations(configurations)
        groups = {}
        configurations.each do |configuration|
          groups[configuration] = build_for_configuration(configuration)
        end

        groups.each do |configuration, group|
          group.reload
          configuration[:ip_permissions].each do |permission|
            authorize(group, permission)
          end
        end
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
