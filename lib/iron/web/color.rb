
# Implements a color (r,g,b + a) with conversion to/from web format (eg #aabbcc), and
# with a number of utilities to lighten, darken and blend values.
class Color

  # Basic attributes - holds each channel as 0-255 fixnum
  attr_reader :r, :g, :b, :a

  # Table for conversion to hex
  HEXVAL = (('0'..'9').to_a).concat(('A'..'F').to_a).freeze
  # Default value for #darken, #lighten etc.
  BRIGHTNESS_DEFAULT = 0.2

  # Construct ourselves from whatever is passed in
  def initialize(*args)
    @r = 255
    @g = 255
    @b = 255
    @a = 255

    if args.size.between?(3,4)
      self.r = args[0]
      self.g = args[1]
      self.b = args[2]
      self.a = args[3] if args[3]
    else
      set(*args)
    end
  end

  # All-purpose setter - pass in another Color, '#000000', rgb vals... whatever
  def set(*args)
    val = Color.parse(*args)
    unless val.nil?
      self.r = val.r
      self.g = val.g
      self.b = val.b
      self.a = val.a
    end
    self
  end

  # Test for equality, accepts string vals as well, eg Color.new('aaa') == '#AAAAAA' => true
  def ==(val)
    val = Color.parse(val)
    return false if val.nil?
    return r == val.r && g == val.g && b == val.b && a == val.a
  end

  # Setters for individual channels - take 0-255 or '00'-'FF' values
  def r=(val); @r = from_hex(val); end
  def g=(val); @g = from_hex(val); end
  def b=(val); @b = from_hex(val); end
  def a=(val); @a = from_hex(val); end

  # Assigns a callback lambda to convert symbols into
  # parse-able values.  Sample usage:
  #   Color.lookup_callback = lambda {|val| Settings[:site][:colors].get!(val) }
  #   rgb(:off_white)  # => '#f8f0ee'
  def self.lookup_callback=(callback)
    @lookup_callback = callback
  end
  
  # Get the lookup callback, if any
  def self.lookup_callback
    @lookup_callback
  end

  # Attempt to read in a string and parse it into values
  def self.parse(*args)
    case args.size

    when 0 then
      return nil

    when 1 then
      val = args[0]

      # Trivial parse... :-)
      return val if val.is_a?(Color)

      # Lookup site settings if symbol
      if val.is_a?(Symbol)
        callback = Color.lookup_callback
        return callback.nil? ? nil : self.parse(callback.call(val))
      end

      # Single value, assume grayscale
      return Color.new(val, val, val) if val.is_a?(Fixnum)

      # Assume string
      str = val.to_s.upcase
      str = str[/[0-9A-F]{3,8}/] || ''
      case str.size
      when 3, 4 then
        r, g, b, a = str.scan(/[0-9A-F]/)
      when 6, 8 then
        r, g, b, a = str.scan(/[0-9A-F]{2}/)
      else
        return nil
      end
      a = 255 if a.nil?

      return Color.new(r,g,b,a)

    when 3,4 then
      return Color.new(*args)

    end
    nil
  end

  def inspect
    to_s
  end

  def to_s(add_hash = true)
    trans? ? to_rgba(add_hash) : to_rgb(add_hash)
  end

  def to_rgb(add_hash = true)
    (add_hash ? '#' : '') + to_hex(r) + to_hex(g) + to_hex(b)
  end

  def to_rgba(add_hash = true)
    to_rgb(add_hash) + to_hex(a)
  end

  def opaque?
    @a == 255
  end

  def trans?
    @a != 255
  end

  def grayscale?
    @r == @g && @g == @b
  end

  # Lighten color by amt
  def lighten(amt = BRIGHTNESS_DEFAULT)
    return self if amt <= 0
    return WHITE if amt >= 1.0
    val = Color.new(self)
    val.r += ((255-val.r) * amt).to_i
    val.g += ((255-val.g) * amt).to_i
    val.b += ((255-val.b) * amt).to_i
    val
  end

  def lighten!(amt = BRIGHTNESS_DEFAULT)
    set(lighten(amt))
    self
  end

  # Darken color by amt
  def darken(amt = BRIGHTNESS_DEFAULT)
    return self if amt <= 0
    return BLACK if amt >= 1.0
    val = Color.new(self)
    val.r -= (val.r * amt).to_i
    val.g -= (val.g * amt).to_i
    val.b -= (val.b * amt).to_i
    val
  end

  def darken!(amt = BRIGHTNESS_DEFAULT)
    set(darken(amt))
    self
  end

  # Go towards middle of brightness scale, based on whether color is dark or light.
  def contrast(amt = BRIGHTNESS_DEFAULT)
    dark? ? lighten(amt) : darken(amt)
  end

  def contrast!(amt = BRIGHTNESS_DEFAULT)
    set(contrast(amt))
    self
  end

  # Convert to grayscale
  def grayscale
    Color.new(self.brightness)
  end

  # Compute our overall brightness, using perception-based weighting, from 0.0 to 1.0
  def brightness
    (0.2126 * self.r + 0.7152 * self.g + 0.0722 * self.b) / 255.0
  end
  
  def dark?
    brightness < 0.5
  end

  def light?
    !dark?
  end

  def grayscale!
    set(grayscale)
    self
  end

  # Blend to a color amt % towards another color value
  def blend(other, amt)
    other = Color.parse(other)
    return Color.new(self) if amt <= 0 || other.nil?
    return Color.new(other) if amt >= 1.0
    val = Color.new(self)
    val.r += ((other.r - val.r)*amt).to_i
    val.g += ((other.g - val.g)*amt).to_i
    val.b += ((other.b - val.b)*amt).to_i
    val
  end

  def blend!(other, amt)
    set(blend(other, amt))
    self
  end

  def self.blend(col1, col2, amt)
    col1 = Color.parse(col1)
    col2 = Color.parse(col2)
    col1.blend(col2, amt)
  end

  def self.average(col1, col2)
    self.blend(col1, col2, 0.5)
  end

  protected

  # Convert int to string hex, eg 255 => 'FF'
  def to_hex(val)
    HEXVAL[val / 16] + HEXVAL[val % 16]
  end

  # Convert int or string to int, eg 80 => 80, 'FF' => 255, '7' => 119
  def from_hex(val)
    if val.is_a?(String)
      # Double up if single char form
      val = val + val if val.size == 1
      # Convert to integer
      val = val.hex
    end
    # Clamp
    val = 0 if val < 0
    val = 255 if val > 255
    val
  end

  public

  # Some constants for general use
  WHITE = Color.new(255,255,255).freeze
  BLACK = Color.new(0,0,0).freeze

end

# "Global" method for creating Color objects, eg:
#   new_color = rgb(params[:new_color])
#   style="border: 1px solid <%= rgb(10,50,80).lighten %>"
def rgb(*args)
  Color.parse(*args)
end
