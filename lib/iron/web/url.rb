require 'cgi'

class Url

  attr_accessor :scheme, :server, :port, :path, :params, :fragment

  SECURE_SCHEMES = ['https', 'sftp', 'ssh'].freeze
  SECURE_SCHEME_MAPPING = { 'http' => 'https', 'ftp' => 'sftp' }.freeze
  SCHEME_DEFAULT_PORTS = {
    'ftp' => 21,
    'ssh' => 22,
    'smtp' => 25,
    'http' => 80,
    'pop3' => 110,
    'pop' => 110,
    'sftp' => 115,
    'imap' => 143,
    'https' => 443,
    'ssl' => 443,
    'irc' => 531,
    'imaps' => 993,
    'pop3s' => 995,
    'pops' => 995
  }.freeze
  
  # Returns a new Url from the given string
  def self.parse(str)
    Url.new(str)
  end

  # Return default domain for urls, used
  # to convert relative urls to absolute
  def self.default_server
    @default_server
  end
  
  def self.default_server=(server)
    @default_server = server
  end

  def self.default_scheme
    @default_scheme || 'http'
  end
  
  def self.default_scheme=(scheme)
    @default_scheme = scheme
  end

  # Construct a full URL from pieces
  def self.build(base, params = {}, fragment = nil)
    url = base + to_param_string(params)
    url += '#' + fragment unless fragment.blank?
    url
  end

  # Construct a param string from key/value pairs
  def self.to_param_string(params)
    str = ''
    # Remove blank/nil keys                                                                                                                  
    params.delete_if {|k,v| v.to_s.blank? || k.to_s.blank?}
    # Convert to param string                                                                                                                
    unless params.empty?
      str += '?'
      str += params.collect do |k,v|
        if v.is_a?(Array)
          k = k.gsub('[]','')
          v.collect do |vs|
            val = vs.respond_to?(:to_param) ? vs.to_param : vs
            val = val.to_s
            CGI::escape(k.to_s) + '[]=' + CGI::escape(val)
          end
        else
          val = v.respond_to?(:to_param) ? v.to_param : v
          val = val.to_s
          CGI::escape(k.to_s) + '=' + CGI::escape(val)
        end
      end.flatten.join('&')
    end
    str
  end

  def initialize(str = nil)
    @scheme = @port = @server = nil
    set(str)
  end
  
  # Parse and set internals from given url
  def set(url)
    # Decompose into major components
    url = (url || '').strip
    base, params, @fragment = url.extract(/^([^\?#]*)\??([^#]*)#?(.*)$/)
    
    # Parse out base
    base ||= ''
    if base.match(/^[a-z\+]*:\/\//)
      @scheme, @server, ignore, @port, @path = base.extract(/^([a-z]*):\/\/([a-z0-9\-_\.]+)(:([0-9]+))?(\/.*)?/i)
      @path ||= ''
      @port = @port.blank? ? nil : @port.to_i
    else
      @path = base
    end
    
    # Parse out params
    @params = {}
    params.split('&').each do |p|
      k, v = p.split('=')
      if k && v
        if k.ends_with?('[]')
          add_param(CGI::unescape(k.gsub('[]','')), [CGI::unescape(v)])
        else
          add_param(CGI::unescape(k), CGI::unescape(v))
        end
      end
    end
  end

  # Makee the url
  def to_s
    Url::build(base, @params, @fragment)
  end
  
  def to_html
    to_s
  end

  def inspect
    to_s
  end

  def empty?
    blank?
  end

  def blank?
    self.base.blank?
  end

  # Returns the full start of the url, minus params and fragment
  def base
    val = ''
    unless @server.blank?
      val = (@scheme || Url::default_scheme) + '://' + @server
      val += ':' + @port.to_s unless @port.to_s.blank?
    end
    p = (@path || '')
    p = '/' + p unless p.blank? || p.starts_with?('/')
    val + p 
  end

  def append_path(str, escape = false)
    str = str.to_s
    @path ||= ''
    @path += escape ? CGI::escape(str).gsub('+', '%20') : str
  end

  def +(str)
    append_path(str)
    self
  end

  # Override current param val or set if none
  def set_param(k, v)
    @params[k.to_s] = v
  end
  
  def set_params(hash)
    hash.each_pair {|k,v|
      set_param(k, v)
    }
  end

  # Add a param value (can be called multiply for the same param key)
  def add_param(k, v)
    k = k.to_s
    oldval = @params[k]
    if oldval
      @params[k] = oldval.is_a?(Array) ? oldval + [v] :  [oldval, v]
      @params[k].flatten!
    else
      @params[k] = v
    end
  end

  # Wipe out keyed value by string match or regex match
  def remove_param(key_or_regex)
    @params.delete_if do |k, v|
      if key_or_regex.is_a?(Regexp)
        k.match(key_or_regex)
      else
        k == key_or_regex.to_s
      end
    end
  end
  
  def get_param(k)
    @params[k.to_s]
  end

  # Reset params
  def clear_params
    @params = {}
  end
  def reset_params ; clear_params ; end
  
  def has_params?
    @params && !@params.empty?
  end

  def secure?
    SECURE_SCHEMES.include?(scheme)
  end
  
  def relative?
    @server.blank?
  end

  def absolute?
    !relative?
  end

  # Ensure url contains a server + scheme section, eg converts '/foo' into 'http://example.com/foo'.
  def make_absolute(secure = false, server = nil)
    unless absolute? && secure? == secure
      raise 'No default server set for Url#make_absolute' unless server || @server || Url.default_server
      @server ||= (server || Url.default_server)
      unless @scheme
        @scheme = Url.default_scheme 
        @port = nil
      end
      if secure
        raise "No secure scheme for scheme #{@scheme} in Url#make_absolute" unless SECURE_SCHEME_MAPPING[@scheme]
        @scheme = SECURE_SCHEME_MAPPING[@scheme]
      end
    end
    to_s
  end

  def make_relative
    unless relative?
      @server = nil
      @scheme = nil
      @port = nil
    end
    to_s
  end

end
