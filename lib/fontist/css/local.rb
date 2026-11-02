module Fontist
  module Css
    # Builds a self-hosted CSS bundle from fonts already installed by
    # fontist: one copied file per style plus fonts.css with one @font-face
    # per style. No downloads, installs or format conversion happen here.
    class Local
      CSS_FORMATS = {
        "woff2" => "woff2",
        "woff" => "woff",
        "ttf" => "truetype",
        "otf" => "opentype",
      }.freeze

      def initialize(family, output_dir:, url_prefix: nil, styles: nil,
                     font_format: nil)
        @family = family.to_s.strip
        @output_dir = output_dir.to_s
        @url_prefix = url_prefix.to_s
        @styles = styles
        @font_format = font_format&.to_s&.downcase
        validate_font_format!
      end

      # @return [String] path of the written fonts.css
      def call
        raise UnknownFamilyError, @family if @family.empty?

        entries = installed_entries
        FileUtils.mkdir_p(@output_dir)
        entries.each { |e| write_font(e) }
        css_path = File.join(@output_dir, "fonts.css")
        File.write(css_path, entries.map { |e| font_face(e) }.join("\n"))
        css_path
      end

      private

      def validate_font_format!
        return if @font_format.nil? || CSS_FORMATS.key?(@font_format)

        raise InvalidOptionError,
              "Unsupported font format '#{@font_format}'. " \
              "Use one of: #{CSS_FORMATS.keys.join(', ')}."
      end

      def installed_entries
        formulas = Formula.find_many(@family)
        raise UnknownFamilyError, @family if formulas.empty?

        faces = formulas.filter_map { |formula| selected_faces(formula) }
        raise UnknownFamilyError, @family if faces.empty?

        faces.each do |candidate|
          entries = locate(candidate)
          return entries unless entries.empty?
        end
        raise Errors::MissingFontError, @family
      end

      # Faces of this family in the formula, narrowed to --styles.
      def selected_faces(formula)
        faces = Styles.faces(formula).select { |f| family?(f.style) }
        return if faces.empty?

        requested = Styles.parse(@styles)
        return faces if requested.empty?

        Styles.verify(@family, faces, requested)
        faces.select { |f| requested.include?(f.tuple) }
      end

      def family?(style)
        name = style.preferred_family_name || style.family_name
        name.to_s.casecmp?(@family)
      end

      def locate(faces)
        files = installed_files
        faces.filter_map { |face| entry_for(face, files) }
      end

      # The installed file in the requested format, or the installed original
      # to convert into it.
      def entry_for(face, files)
        path = files[wanted_name(face.style.font)]
        return { path: path, face: face, ext: extension(path) } if path
        return unless @font_format

        original = files[File.basename(face.style.font.to_s).downcase]
        return unless original

        { path: original, face: face, ext: @font_format, convert: true }
      end

      def extension(path)
        File.extname(path).delete(".")
      end

      def write_font(entry)
        if entry[:convert]
          FontOperations::Convert.call(entry[:path], @font_format,
                                       target(entry))
        else
          FileUtils.cp(entry[:path], target(entry))
        end
      end

      # A file name keyed by lowercase basename, so extension swaps match.
      def wanted_name(font)
        stem = File.basename(font.to_s, ".*")
        ext = @font_format || File.extname(font.to_s).delete(".")
        "#{stem}.#{ext}".downcase
      end

      def installed_files
        patterns = Utils.font_file_patterns(Fontist.fonts_path.join("**").to_s)
        patterns.flat_map { |p| Dir.glob(p) }.sort
          .to_h { |path| [File.basename(path).downcase, path] }
      end

      def target(entry)
        name = "#{File.basename(entry[:path], '.*')}.#{entry[:ext]}"
        File.join(@output_dir, name)
      end

      def font_face(entry)
        name = File.basename(target(entry))
        face = entry[:face]
        <<~CSS
          @font-face {
            font-family: "#{escape(@family)}";
            src: url("#{escape(url_for(name))}") format("#{css_format(entry)}");
            font-weight: #{face.weight};
            font-style: #{face.italic ? 'italic' : 'normal'};
          }
        CSS
      end

      def url_for(name)
        encoded = CGI.escape(name).gsub("+", "%20")
        prefix = @url_prefix.chomp("/")
        prefix.empty? ? encoded : "#{prefix}/#{encoded}"
      end

      def css_format(entry)
        CSS_FORMATS.fetch(entry[:ext].downcase) do
          raise InvalidOptionError,
                "Cannot describe font file format '#{entry[:ext]}' in CSS."
        end
      end

      def escape(text)
        text.to_s.gsub(/[\\"]/) { |c| "\\#{c}" }.gsub(/\r?\n/, "\\A ")
      end
    end
  end
end
