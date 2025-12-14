# frozen_string_literal: true

require "unibuf"
require_relative "models/metadata"

module Fontist
  module Import
    module Google
      # Adapts unibuf's generic Message model to our domain Metadata model
      #
      # This adapter bridges between the generic protocol buffer parser (unibuf)
      # and our rich domain model (Models::Metadata), extracting and transforming
      # all fields according to our business requirements.
      #
      # @example Basic usage
      #   unibuf_message = Unibuf.parse_textproto_file("METADATA.pb")
      #   metadata = MetadataAdapter.adapt(unibuf_message)
      #   puts metadata.name # => "Roboto"
      class MetadataAdapter
        # Adapt unibuf message to Metadata model
        #
        # @param unibuf_message [Unibuf::Models::Message] parsed message from unibuf
        # @return [Models::Metadata] domain metadata model with rich behavior
        def self.adapt(unibuf_message)
          hash = extract_metadata_hash(unibuf_message)
          Models::Metadata.new(hash)
        end

        # Extract metadata hash from unibuf message
        #
        # @param message [Unibuf::Models::Message] parsed message
        # @return [Hash] hash suitable for Models::Metadata.new
        private_class_method def self.extract_metadata_hash(message)
          {
            "name" => field_value(message, "name"),
            "designer" => field_value(message, "designer"),
            "license" => field_value(message, "license"),
            "category" => field_value(message, "category"),
            "date_added" => field_value(message, "date_added"),
            "fonts" => extract_fonts(message),
            "subsets" => find_all_values(message, "subsets"),
            "axes" => extract_axes(message),
            "source" => extract_source(message),
            "registry_default_overrides" => extract_registry_overrides(message),
            "is_noto" => field_boolean(message, "is_noto"),
            "languages" => find_all_values(message, "languages"),
            "primary_script" => field_value(message, "primary_script"),
          }.compact
        end

        # Get field value as string
        private_class_method def self.field_value(message, name)
          field = message.find_field(name)
          return nil unless field

          field.value.to_s
        end

        # Get field value as boolean
        private_class_method def self.field_boolean(message, name)
          field = message.find_field(name)
          return nil unless field

          value = field.value.to_s
          value == "true"
        end

        # Get all values for repeated field
        private_class_method def self.find_all_values(message, name)
          fields = message.find_fields(name)
          return nil if fields.empty?

          fields.map { |f| f.value.to_s }
        end

        # Extract fonts array
        private_class_method def self.extract_fonts(message)
          font_fields = message.find_fields("fonts")
          return nil if font_fields.empty?

          font_fields.map do |field|
            next unless field.message_field?

            # field.value is a Hash for message fields in unibuf
            font_hash = field.value
            next unless font_hash.is_a?(Hash) && font_hash["fields"]

            font_msg = create_message_from_hash(font_hash)
            {
              "name" => field_value(font_msg, "name"),
              "style" => field_value(font_msg, "style"),
              "weight" => field_integer(font_msg, "weight"),
              "filename" => field_value(font_msg, "filename"),
              "post_script_name" => field_value(font_msg, "post_script_name"),
              "full_name" => field_value(font_msg, "full_name"),
              "copyright" => field_value(font_msg, "copyright"),
            }.compact
          end.compact
        end

        # Extract axes array
        private_class_method def self.extract_axes(message)
          axis_fields = message.find_fields("axes")
          return nil if axis_fields.empty?

          axis_fields.map do |field|
            next unless field.message_field?

            axis_hash = field.value
            next unless axis_hash.is_a?(Hash) && axis_hash["fields"]

            axis_msg = create_message_from_hash(axis_hash)
            {
              "tag" => field_value(axis_msg, "tag"),
              "min_value" => field_float(axis_msg, "min_value"),
              "max_value" => field_float(axis_msg, "max_value"),
              "default_value" => field_float(axis_msg, "default_value"),
            }.compact
          end.compact
        end

        # Extract source information
        private_class_method def self.extract_source(message)
          source_field = message.find_field("source")
          return nil unless source_field&.message_field?

          source_hash = source_field.value
          return nil unless source_hash.is_a?(Hash) && source_hash["fields"]

          source_msg = create_message_from_hash(source_hash)
          {
            "repository_url" => field_value(source_msg, "repository_url"),
            "commit" => field_value(source_msg, "commit"),
            "archive_url" => field_value(source_msg, "archive_url"),
            "branch" => field_value(source_msg, "branch"),
            "config_yaml" => field_value(source_msg, "config_yaml"),
            "files" => extract_files(source_msg),
          }.compact
        end

        # Extract source files array
        private_class_method def self.extract_files(source_msg)
          file_fields = source_msg.find_fields("files")
          return nil if file_fields.empty?

          file_fields.map do |field|
            next unless field.message_field?

            file_hash = field.value
            next unless file_hash.is_a?(Hash) && file_hash["fields"]

            file_msg = create_message_from_hash(file_hash)
            {
              "source_file" => field_value(file_msg, "source_file"),
              "dest_file" => field_value(file_msg, "dest_file"),
            }.compact
          end.compact
        end

        # Extract registry default overrides as hash
        private_class_method def self.extract_registry_overrides(message)
          override_fields = message.find_fields("registry_default_overrides")
          return nil if override_fields.empty?

          overrides = {}
          override_fields.each do |field|
            next unless field.message_field?

            override_hash = field.value
            next unless override_hash.is_a?(Hash) && override_hash["fields"]

            # Each override is a message with key and value fields
            override_msg = create_message_from_hash(override_hash)
            key = field_value(override_msg, "key")
            value = field_float(override_msg, "value")
            overrides[key] = value if key && value
          end

          overrides.empty? ? nil : overrides
        end

        # Create a Message-like object from hash for field queries
        private_class_method def self.create_message_from_hash(hash)
          # Convert hash representation back to queryable object
          # hash has structure: {"fields" => [{"name" => "...", "value" => "..."}]}
          MessageWrapper.new(hash)
        end

        # Helper class to wrap hash as queryable message
        class MessageWrapper
          def initialize(hash)
            @fields_data = hash["fields"] || []
          end

          def find_field(name)
            field_data = @fields_data.find { |f| f["name"] == name }
            return nil unless field_data

            FieldWrapper.new(field_data)
          end

          def find_fields(name)
            @fields_data.select do |f|
              f["name"] == name
            end.map { |f| FieldWrapper.new(f) }
          end
        end

        # Helper class to wrap field data
        class FieldWrapper
          def initialize(field_data)
            @field_data = field_data
          end

          def value
            ValueWrapper.new(@field_data["value"])
          end

          def message_field?
            @field_data["value"].is_a?(Hash) && @field_data["value"]["fields"]
          end
        end

        # Helper class to wrap values
        class ValueWrapper
          def initialize(value)
            @value = value
          end

          def to_s
            @value.to_s
          end

          def message
            return nil unless @value.is_a?(Hash)

            MessageWrapper.new(@value)
          end
        end

        # Get field value as integer
        private_class_method def self.field_integer(message, name)
          field = message.find_field(name)
          return nil unless field

          field.value.to_s.to_i
        end

        # Get field value as float
        private_class_method def self.field_float(message, name)
          field = message.find_field(name)
          return nil unless field

          field.value.to_s.to_f
        end
      end
    end
  end
end
