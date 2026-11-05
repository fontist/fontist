module Fontist
  # `fontist convert ...`: Fontisan operations on font files the user
  # already has, without installing anything.
  class ConvertCLI < Thor
    include CLI::ClassOptions

    desc "format FONT_FILE FORMAT",
         "Convert FONT_FILE to FORMAT (ttf, otf, woff, woff2)"
    option :output, aliases: :o,
                    desc: "Output file (default: FONT_FILE, new extension)"
    def to_format(source, target)
      default = replace_ext(source, ".#{target.to_s.downcase}")
      write_font do
        output = output_for(source, default)
        FontOperations::Convert.call(source, target, output)
      end
    end
    map "format" => :to_format

    desc "extract COLLECTION", "Write one member of a TTC/OTC collection"
    option :index, type: :numeric, required: true,
                   desc: "Zero-based member index"
    option :output_dir, desc: "Output directory (default: next to COLLECTION)"
    def extract(collection)
      dir = options[:output_dir] || File.dirname(collection)
      write_font do
        FontOperations::Extract.call(collection, index: options[:index],
                                                 output_dir: dir)
      end
    end

    desc "instance FONT_FILE AXES",
         "Write a static instance of a variable font (e.g. wght=300,wdth=90)"
    option :output, aliases: :o,
                    desc: "Output file (default: FONT_FILE named after AXES)"
    def instance(source, axes)
      write_font do
        coords = FontOperations::Instance.parse(axes)
        name = FontOperations::Instance.file_name(File.basename(source), coords)
        default = File.join(File.dirname(source), name)
        FontOperations::Instance.call(source, output_for(source, default),
                                      coordinates: coords)
      end
    end

    desc "subset FONT_FILE", "Keep only the glyphs for the given characters"
    option :unicodes, desc: "Codepoints to keep (e.g. 'U+0020-007E,U+00E9')"
    option :text, desc: "Characters to keep"
    option :output, aliases: :o,
                    desc: "Output file (default: FONT_FILE with -subset)"
    def subset(source)
      default = replace_ext(source, "-subset#{File.extname(source)}")
      write_font do
        FontOperations::Subset.call(source, output_for(source, default),
                                    unicodes: options[:unicodes],
                                    text: options[:text])
      end
    end

    private

    def write_font
      handle_class_options(options)
      path = yield
      Fontist.ui.success("Written to #{path}")
      CLI::STATUS_SUCCESS
    rescue Errors::GeneralError => e
      Fontist.ui.error(e.message)
      CLI::STATUS_UNKNOWN_ERROR
    end

    # The given --output, or +default+; never the source itself.
    def output_for(source, default)
      output = options[:output] || default
      if File.expand_path(output) == File.expand_path(source)
        raise FontOperations::Error,
              "Output would overwrite #{source}. Give a different --output."
      end

      output
    end

    def replace_ext(path, suffix)
      File.join(File.dirname(path),
                File.basename(path, File.extname(path)) + suffix)
    end
  end
end
