# frozen_string_literal: true

module Facter
  module Resolvers
    module Macosx
      class Mountpoints < BaseResolver
        include Facter::Util::Resolvers::FilesystemHelper
        init_resolver

        class << self
          private

          def post_resolve(fact_name, _options)
            @fact_list.fetch(fact_name) { read_mounts }
          end

          def read_mounts
            mounts = {}
            begin
              Facter::Util::Resolvers::FilesystemHelper.read_mountpoints.each do |fs|
                device = fs.name
                filesystem = fs.mount_type
                path = fs.mount_point
                options = read_options(fs.options)

                mounts[path] = read_stats(path).tap do |hash|
                  hash[:device] = device
                  hash[:filesystem] = filesystem
                  hash[:options] = options if options.any?
                end
              end
            rescue LoadError => e
              @log.debug("Could not read mounts: #{e}")
            end

            @fact_list[:mountpoints] = mounts
          end

          def read_stats(path)
            begin
              stats = Facter::Util::Resolvers::FilesystemHelper.read_mountpoint_stats(path)
              size_bytes = stats.bytes_total
              available_bytes = stats.bytes_available
              used_bytes = size_bytes - available_bytes
            rescue Sys::Filesystem::Error, LoadError
              size_bytes = used_bytes = available_bytes = 0
            end

            {
              size_bytes: size_bytes,
              used_bytes: used_bytes,
              available_bytes: available_bytes,
              capacity: Facter::Util::Resolvers::FilesystemHelper.compute_capacity(used_bytes, size_bytes),
              size: Facter::Util::Facts::UnitConverter.bytes_to_human_readable(size_bytes),
              available: Facter::Util::Facts::UnitConverter.bytes_to_human_readable(available_bytes),
              used: Facter::Util::Facts::UnitConverter.bytes_to_human_readable(used_bytes)
            }
          end

          def read_options(options)
            options_map = {
              'read-only' => 'readonly',
              'asynchronous' => 'async',
              'synchronous' => 'noasync',
              'quotas' => 'quota',
              'rootfs' => 'root',
              'defwrite' => 'deferwrites'
            }

            options.split(',').map(&:strip).map { |o| options_map.key?(o) ? options_map[o] : o }
          end
        end
      end
    end
  end
end
