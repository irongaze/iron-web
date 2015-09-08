require 'iron/web/html/element'

# == Html Creation and Rendering
#
# This class, combined with the Html::Element class, provides a DSL for html creation, similar to the XmlBuilder class, but tailored for HTML generation.
#
# An Html class instance is an ordered collection of Html::Elements and Strings, that together can be rendered out as HTML.
#
# Usage:
#
# Html.build do |html|
#   html.div(:id => 'some-div') {
#     html.em('HTML is neat!')
#   }
# end
#
class Html

  # Constants
  HTML_ESCAPE = {"&"=>"&amp;", ">"=>"&gt;", "<"=>"&lt;", "\""=>"&quot;"}.freeze
  JS_ESCAPE = {'\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'"}.freeze

  # Remove everything that would normally come from Object and Kernel etc. so our keys can be anything
  instance_methods.each do |m| 
    keepers = [] #['inspect']
    undef_method m if m =~ /^[a-z]+[0-9]?$/ && !keepers.include?(m)
  end

  # So we can behave as a collection
  include Enumerable
  undef_method :select  #This is an HTML tag, dammit

  # Primary entry point for HTML generation using these tools.
  def self.build
    builder = Html.new
    yield builder if block_given?
    builder.render.html_safe
  end

  # The escape methods #escape_once and #escape_javascript are both taken from Rails, which like this library is MIT
  # licensed.  The following license statement applies to those two methods and the constants they reference.  Thanks
  # Rails team!
  #
  # Copyright © 2004-2013 David Heinemeier Hansson
  # Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
  # documentation files (the “Software”), to deal in the Software without restriction, including without limitation
  # the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
  # to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included in all copies or substantial portions
  # of the Software.
  #
  # THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
  # TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  # THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  # CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  # DEALINGS IN THE SOFTWARE.
  #
  # Ripped from Rails...
  def self.escape_once(html)
    return html if html.html_safe?
    html.to_s.gsub(/[\"><]|&(?!([a-zA-Z]+|(#\d+));)/) { |special| HTML_ESCAPE[special] }.html_safe
  end
  
  # And again, thanks Rails team!
  def self.escape_javascript(js)
    if js
      res = js.gsub(/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|special| JS_ESCAPE[special] }
      js.html_safe? ? res.html_safe : res
    else
      ''
    end
  end
  
  # Sets up internal state, natch, and accepts a block that customizes the resulting object.
  def initialize
    @items = []
    @item_stack = []
    yield self if block_given?
  end
  
  # Inserts an HTML comment (eg <!-- yo -->)
  def comment!(str)
    if str.include? "\n"
      text! "<!--\n#{str}\n-->\n"
    else
      text! "<!-- #{str} -->\n"
    end
  end
  
  # Inserts raw text
  def text!(str)
    self << str
  end
  
  # Allow pushing new elements
  def <<(new_item)
    if @item_stack.empty?
      @items << new_item
    else
      @item_stack.last.html << new_item
    end
    self
  end
  
  # Implement enumerable
  def each
    @items.each {|v| yield v} if block_given?
  end
  
  def count
    @items.count
  end

  def empty?
    @items.empty?
  end
  
  def blank?
    empty?
  end
  
  # Create a new element explicitly
  def tag(tag, *args, &block)
    item = Html::Element.new(tag, *args)
    self << item
    if block
      @item_stack.push item
      block.call(item) 
      @item_stack.pop
    end
    return self
  end

  # Creates a new element on any method missing calls.
  # Returns self, so you can chain calls (eg html.div('foo').span('bar') )
  def method_missing(method, *args, &block)
    parts = method.to_s.match(/^([a-z]+[0-9]?)$/)
    if parts
      # Assume it's a new element, create the tag
      tag(parts[1], *args, &block)
    else
      # There really is no method...
      super
    end
  end
  
  # Make sure our objects advertise their support of tags
  def respond_to_missing?(method, include_private)
    parts = method.to_s.match(/^([a-z]+[0-9]?)$/)
    if parts
      true
    else
      super
    end
  end

  # Renders out as html - accepts depth param to indicate level of indentation
  def render(depth = 0, inblock = true)
    # Convert elements to strings
    @items.collect do |item|
      if item.is_a?(String)
        if inblock
          inblock = false
          '  '*depth + item
        else
          item
        end
      elsif item.nil?
        ''
      else
        item.render(depth,inblock)
      end
    end.join('')
  end

  # Alias for #render
  def to_s
    render
  end

  # Alias for #render
  def inspect
    render
  end

  def is_a?(other)
    return other == Html
  end

end
