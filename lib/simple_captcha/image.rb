require 'tempfile'
module SimpleCaptcha #:nodoc
  module ImageHelpers #:nodoc

    mattr_accessor :image_styles
    @@image_styles = {
      'embosed_silver'   => ['-fill darkblue', '-shade 20x60', '-background white'],
      'simply_red'       => ['-fill darkred', '-background white'],
      'simply_green'     => ['-fill darkgreen', '-background white'],
      'simply_blue'      => ['-fill darkblue', '-background white'],
      'distorted_black'  => ['-fill darkblue', '-edge 10', '-background white'],
      'all_black'        => ['-fill darkblue', '-edge 2', '-background white'],
      'charcoal_grey'    => ['-fill darkblue', '-charcoal 5', '-background white'],
      'almost_invisible' => ['-fill red', '-solarize 50', '-background white']
    }

    DISTORTIONS = ['low', 'medium', 'high']
    IMPLODES = { 'none' => 0, 'low' => 0.1, 'medium' => 0.2, 'high' => 0.3 }
    DEFAULT_IMPLODE = 'medium'

    class << self
      def image_params(key = 'simply_blue')
        image_keys = @@image_styles.keys
        style = if key == 'random'
                  image_keys.sample
                else
                  image_keys.include?(key) ? key : 'simply_blue'
                end
        @@image_styles[style]
      end

      def distortion(key = 'low')
        key = key == 'random' ? DISTORTIONS.sample : (DISTORTIONS.include?(key) ? key : 'low')
        case key.to_s
        when 'low'    then [rand(2), 80 + rand(20)]
        when 'medium' then [2 + rand(2), 50 + rand(20)]
        when 'high'   then [4 + rand(2), 30 + rand(20)]
        end
      end

      def implode
        IMPLODES[SimpleCaptcha.implode] || IMPLODES[DEFAULT_IMPLODE]
      end
    end

    if RUBY_VERSION < '1.9'
      class Tempfile < ::Tempfile
        # Replaces Tempfile's +make_tmpname+ with one that honors file extensions.
        def make_tmpname(basename, n = 0)
          extension = File.extname(basename)
          sprintf("%s,%d,%d%s", File.basename(basename, extension), $$, n, extension)
        end
      end
    end

    private

    def generate_simple_captcha_image(simple_captcha_key) #:nodoc:
      amplitude, frequency = ImageHelpers.distortion(SimpleCaptcha.distortion)
      text = Utils::simple_captcha_value(simple_captcha_key)

      # Build the base image using the label.
      base_params = []
      base_params << "-size #{SimpleCaptcha.image_size}"
      base_params << "label:#{text}"
      base_params << "-gravity Center"
      base_params << "-pointsize 22"
      base_params << ("-font #{SimpleCaptcha.font}" unless SimpleCaptcha.font.empty?)
      base_params.compact!

      # Get the style options (e.g. background, fill, etc.)
      style_options = ImageHelpers.image_params(SimpleCaptcha.image_style).dup

      # Build the effect options (must come after the label image is generated)
      effects = []
      effects << "-wave #{amplitude}x#{frequency}"
      effects << "-implode #{ImageHelpers.implode}"
      if SimpleCaptcha.noise && SimpleCaptcha.noise > 0
        effects << "-evaluate Uniform-noise #{SimpleCaptcha.noise}"
      end

      # Combine all parameters and set the output format to PNG.
      params = base_params + style_options + effects
      params << "png:-"

      # Run the command using 'magick' (make sure your image_magick_path is set properly if needed)
      SimpleCaptcha::Utils::run("magick", params.join(' '))
    end
  end
end
