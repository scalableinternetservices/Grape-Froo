require 'tempfile'
require 'rmagick'
# Adapted from github.com/cmdrkeene/memegen
module Memeutil
  class << self
    def memeify(template_img, top, bottom)
      top = (top || '')
      bottom = (bottom || '')
      if template_img.starts_with?('//')
        template_img = 'http:' + template_img
      end
      template_img.sub!(/^https/, 'http') # don't use https for speed
      content_type = ""
      original_filename = File.basename(URI.parse(template_img).path)
      imgblob = open(template_img) do |f|
        content_type = f.content_type
        f.read
      end
      canvas = Magick::ImageList.new
      canvas.from_blob(imgblob)
      image = canvas.first

      draw = Magick::Draw.new
      draw.font = File.join(Rails.root, "lib/Impact.ttf")
      draw.font_weight = Magick::BoldWeight

      pointsize = image.columns / 5.0
      stroke_width = pointsize / 30.0

      canvas.each do |frame|
        # Draw top
        unless top.empty?
          scale, text = scale_text(top)
          top_draw = draw.dup
          top_draw.annotate(frame, 0, 0, 0, 0, text) do
            self.interline_spacing = -(pointsize / INTERLINE_SPACING_RATIO) * scale
            self.stroke_antialias(true)
            self.stroke = "black"
            self.fill = "white"
            self.gravity = Magick::NorthGravity
            self.stroke_width = stroke_width * scale
            self.pointsize = pointsize * scale
          end
        end
        # Draw bottom
        unless bottom.empty?
          scale, text = scale_text(bottom)
          bottom_draw = draw.dup
          bottom_draw.annotate(frame, 0, 0, 0, 0, text) do
            self.interline_spacing = -(pointsize / INTERLINE_SPACING_RATIO) * scale
            self.stroke_antialias(true)
            self.stroke = "black"
            self.fill = "white"
            self.gravity = Magick::SouthGravity
            self.stroke_width = stroke_width * scale
            self.pointsize = pointsize * scale
          end
        end
      end
      f = StringIO.open(canvas.to_blob)
      f.class.class_eval { attr_accessor :original_filename, :content_type }
      f.original_filename = original_filename
      f.content_type = content_type
      return f
    end

    private
    INTERLINE_SPACING_RATIO = 8
    def word_wrap(txt, col = 80)
      txt.gsub(/(.{1,#{col + 4}})(\s+|\Z)/, "\\1\n")
    end

    def scale_text(text)
      text = text.dup
      if text.length < 10
        scale = 1.0
      elsif text.length < 24
        text = word_wrap(text, 10)
        scale = 0.70
      elsif text.length < 48
        text = word_wrap(text, 15)
        scale = 0.5
      else
        text = word_wrap(text, 20)
        scale = 0.4
      end
      [scale, text.strip]
    end
  end
end
