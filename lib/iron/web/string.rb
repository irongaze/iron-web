# Only add these changes if we're NOT running Rails
unless ''.respond_to?(:html_safe)

# Add Rails-like html safeness awareness to objects
class Object
  
  def html_safe?
    false
  end

end

# Add Rails-like html safeness awareness to strings
class String
  
  # Return a copy of the string marked as being html safe (ie not requiring further encoding)
  def html_safe
    HtmlSafeString.new(self)
  end
  
end

# Simple class that extends strings to do html escapes on incoming concats, only defined
# if not running under Rails
class HtmlSafeString < String

  def initialize(*args)
    @html_safe = true
    super
  end
  
  def html_safe?
    @html_safe
  end
  
  def html_safe
    self
  end

  # The magic - escape values that are concatenated onto this string
  # before concatenation.
  def concat(value)
    if !html_safe? || value.html_safe?
      super(value)
    else
      super(Html.escape_once(value))
    end
  end
  
  def +(other)
    dup.concat(other)
  end
  
  def <<(value)
    concat(value)
  end

end

end