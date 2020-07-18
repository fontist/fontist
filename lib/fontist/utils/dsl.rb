module Fontist
  module Utils
    module Dsl
      def key(key)
        instance.key = key
      end

      def desc(description)
        instance.description = description
      end

      def homepage(homepage)
        instance.homepage = homepage
      end

      def resource(resource_name, &block)
        instance.resources[resource_name] ||= {}
        instance.temp_resource = instance.resources[resource_name]

        yield(block) if block_given?
        instance.temp_resource = {}
      end

      def url(url)
        instance.temp_resource.merge!(urls: [url])
      end

      def urls(urls = [])
        instance.temp_resource.merge!(urls: urls)
      end

      def sha256(sha256)
        instance.temp_resource.merge!(sha256: sha256)
      end

      def file_size(file_size)
        instance.temp_resource.merge!(file_size: file_size )
      end

      def provides_font_collection(name = nil, &block)
        instance.temp_resource = {}
        yield(block) if block_given?
        instance.temp_resource = {}
      end

      def filename(name)
        instance.temp_resource.merge!(filename: name)
      end

      def provides_font(font, options = {})
        font_styles = instance.extract_font_styles(options)
        instance.font_list.push(name: font, styles: font_styles)
      end

      def test
      end

      def requires_license_agreement(license)
        instance.license = license
        instance.license_required = true
      end

      def open_license(license)
        instance.license = license
        instance.license_required = false
      end

      def license_url(url)
        instance.license_url = url
      end

      def display_progress_bar(value )
        instance.options = (instance.options || {}).merge(progress_bar: value )
      end
    end
  end
end
