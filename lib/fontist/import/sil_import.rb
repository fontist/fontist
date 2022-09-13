require "nokogiri"
require "fontist/import/create_formula"

module Fontist
  module Import
    class SilImport
      ROOT = "https://software.sil.org/fonts/".freeze

      def call
        links = font_links
        Fontist.ui.success("Found #{links.size} links.")

        paths = []
        links.each do |link|
          path = create_formula_by_page_link(link)
          paths << path if path
        end

        Fontist::Index.rebuild

        Fontist.ui.success("Created #{paths.size} formulas.")
      end

      private

      def font_links
        html = URI.parse(ROOT).open.read
        document = Nokogiri::HTML.parse(html)
        document.css("table.products div.title > a")
      end

      def create_formula_by_page_link(link)
        url = find_archive_url_by_page_link(link)
        return unless url

        create_formula_by_archive_url(url)
      end

      def create_formula_by_archive_url(url)
        path = Fontist::Import::CreateFormula.new(url,
                                                  formula_dir: formula_dir).call
        Fontist.ui.success("Formula has been successfully created: #{path}")

        path
      end

      def find_archive_url_by_page_link(link)
        Fontist.ui.print("Searching for an archive of #{link.content}... ")

        page_uri = URI.join(ROOT, link[:href])
        archive_uri = find_archive_url_by_page_uri(page_uri)
        unless archive_uri
          Fontist.ui.error("NOT FOUND")
          return
        end

        Fontist.ui.success("DONE")

        archive_uri.to_s
      end

      def find_archive_url_by_page_uri(uri)
        response = uri.open
        current_url = response.base_uri
        html = response.read
        document = Nokogiri::HTML.parse(html)
        link = find_archive_link(document)
        return URI.join(current_url, link[:href]) if link

        page_link = find_download_page(document)
        return unless page_link

        page_uri = URI.join(current_url, page_link[:href])
        find_archive_url_by_page_uri(page_uri)
      end

      def find_archive_link(document)
        links = document.css("a.btn-download")
        download_links = links.select do |tag|
          tag.content.include?("DOWNLOAD CURRENT VERSION")
        end
        return download_links.first unless download_links.empty?

        links = document.css("a")
        download_links = links.select do |tag|
          tag.content.match?(/Download.*\.zip/)
        end
        download_links.first
      end

      def find_download_page(document)
        links = document.css("a.btn-download")
        page_links = links.select { |tag| tag.content == "DOWNLOADS" }
        page_links.first
      end

      def formula_dir
        @formula_dir ||= Fontist.formulas_path.join("sil").tap do |path|
          FileUtils.mkdir_p(path) unless File.exist?(path)
        end
      end
    end
  end
end
