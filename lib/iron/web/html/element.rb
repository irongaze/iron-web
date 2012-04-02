
# = HTML Element Class
#
# Used with the Html class to generate html content for a single tag/element.  Represents
# a single element with attributes and optional contents (including other elements).  Generally, you
# won't use this by itself.  Check out Html.build() instead.
# 
# Simple useage:
#   >> Html::Element.new('span','some text', :id => 'title-text').render
#   => '<span id="title-text">some text</span>'
#
# Complex usage:
#   span = Html::Element.new('span')   # Creates a span element for customization
#   span.id = 'title-text'       # Set some attributes
#   span.style = 'color: #f00;'
#   span.html = 'some text'      # Adds some content
#   span.render                  # Converts to html string
#   => '<span id="title-text" style="color: #f00;">some text</span>
#
class Html
  class Element
    # Remove everything that would normally come from Object and Kernel etc. so our attrs can be anything
    instance_methods.each { |m| undef_method m if m =~ /^[a-z0-9]+=?$/ }

    # Add back in our accessors
    attr_accessor :tag, :attrs

    # Commonly empty tags
    SINGLETON_SET = ['area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source'].freeze
    # Inline formatting tags
    INLINE_SET = ['a','abbr','b','button','em','i','input','img','label','li','option','span','strong','title','textarea','u'].freeze
    # Attributes that should render even if blank
    BLANK_ATTRS = ['value','alt'].freeze

    # One-stop shop for building content
    def self.build(*args)
      el = self.new(*args)
      yield el if block_given?
      el.render
    end

    def initialize(tag, text=nil, attrs={})
      @tag = tag.to_s
      @force_end = !SINGLETON_SET.include?(@tag)
      @skip_newline = INLINE_SET.include?(@tag)

      if text.is_a?(Hash)
        @attrs = text
        text = nil
      else
        @attrs = attrs || {}
      end

      if text.is_a?(String)
        html << ((!text.respond_to?(:html_safe?) || !text.html_safe?) ? Html.escape_once(text) : text)
      elsif text.is_a?(Html::Element)
        html << text
      elsif text.is_a?(Html)
        @html = text
      end

      yield self if block_given?
    
      self
    end

    def force_end!
      @force_end = true
    end

    def skip_newline!
      @skip_newline = true
    end

    def html
      @html ||= Html.new
      @html
    end

    def html=(arg)
      if arg.is_a? String
        @html = Html.new
        @html.text! arg
      elsif arg.is_a?(Html)
        @html = arg
      elsif arg.is_a?(Array)
        @html = Html.new
        arg.each do |el|
          @html << el
        end
      else
        raise 'Invalid input'
      end
    end

    # Set/get attrs on any method missing calls
    def method_missing(method, *args)
      parts = method.to_s.match(/^([a-z0-9_]+)(=?)$/i)
      if parts
        key = parts[1].to_sym
        if parts[2] && args.length == 1
          # We have an attempt to set a missing field...
          @attrs[key] = args[0]
          return args[0]
        else
          raise "I think you meant <#{@tag}>.html.#{method} instead of <#{@tag}>.#{method}" if block_given?
          return @attrs[key]
        end
      else
        # There really is no method...
        super
      end
    end

    def to_s
      render
    end

    def inspect
      render
    end

    def is_a?(other)
      return other == Html::Element
    end

    def render(depth = 0, inblock = false)
      # Convert attrs to strings
      attrStr = @attrs.collect do |k,v|
        if v.nil?
          nil
        elsif v.blank? && ! BLANK_ATTRS.include?(k.to_s)
          " #{k}"
        else
          v = Html.escape_once(v) unless v.html_safe?
          " #{k}=\"#{v}\""
        end
      end.compact.join('')

      # Build start tag
      val = ''
      val += "\n" if !inblock && !@skip_newline
      val += '  ' * depth unless !inblock && @skip_newline
      val += "<#{@tag}#{attrStr}>"
      unless @html.nil?
        val += "\n" unless @skip_newline
        val += @html.render(depth+1, !@skip_newline)
        val += "\n" unless @skip_newline || val.ends_with?("\n")
        val += '  ' * depth unless @skip_newline
      end
      val += "</#{@tag}>" if (@force_end || !@html.blank?)
      val += "\n" unless @skip_newline
      val
    end

  end
end
