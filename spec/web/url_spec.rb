describe Url do
  
  before do
    Url.default_port = nil
    Url.default_server = nil
  end
  
  it 'should parse url paths' do
    {
      '/' => '/',
      'http://google.com' => '',
      '/site/main-bar?foo=123bar#some_bit' => '/site/main-bar'
    }.each_pair do |url, path|
      Url.parse(url).path.should == path
    end
  end
  
  it 'should parse servers' do 
    {
      '/' => nil,
      'google.com' => nil,
      'http://google.com' => 'google.com',
      'http://google.com:8080' => 'google.com',
      'http://www3.text-mates.org.uk:1234?foo' => 'www3.text-mates.org.uk',
      'http://abc.com/yes.com/no.com#fun' => 'abc.com'
    }.each_pair do |url, server|
      Url.parse(url).server.should == server
    end
  end

  it 'should parse a really complex url' do
    u = Url.parse('sftp://mondo122.goober.com:819/this/is-a-bunch.jpg?of=crazy&free[]=55#now')
    u.scheme.should == 'sftp'
    u.server.should == 'mondo122.goober.com'
    u.port.should == 819
    u.path.should == '/this/is-a-bunch.jpg'
    u.params['of'].should == 'crazy'
    u.params['free'].should == ['55']
    u.fragment.should == 'now'
  end
  
  it 'should construct a simple url' do
    u = Url.new
    u.path = '/bob.jpg'
    u.to_s.should == '/bob.jpg'
  end
  
  it 'should construct a complex url' do
    u = Url.new
    u.server = 'jimbo.net.org'
    u.port = 1044
    u.path = '/south-west'
    u.add_param('site', 'http://goober.com?123')
    u.fragment = 'boggle-noggle'
    u.to_s.should == 'http://jimbo.net.org:1044/south-west?site=http%3A%2F%2Fgoober.com%3F123#boggle-noggle'
  end
  
  it 'should allow adding params' do
    u = Url.parse('http://irongaze.com')
    u.params['foo'] = 'bar'
    u.to_s.should == 'http://irongaze.com?foo=bar'
  end
  
  it 'should allow multiple values for a single param' do
    u = Url.new('/scores')
    u.add_param('soccer', '123')
    u.add_param('soccer', '456')
    u.to_s.should match(/soccer\[\]=/)
    u = Url.parse(u.to_s)
    val = u.params['soccer']
    val.should be_an(Array)
    val.length.should == 2
    val[1].should == '456'
  end
  
  it 'should allow resetting params' do
    u = Url.parse('/?a=1&b=2')
    u.params.length.should == 2
    u.reset_params
    u.should_not have_params
  end
  
  it 'should allow removing a param' do 
    u = Url.parse('/?a=1&b=2')
    u.remove_param('a')
    u.params.length.should == 1
    u.to_s.should == '/?b=2'
  end
  
  it 'should expand arrays in params' do
    u = Url.build('/foo', :bar => [1,2])
    u.to_s.should == '/foo?bar[]=1&bar[]=2'
  end
  
  it 'should support adding to the path' do
    u = Url.parse('/')
    u += 'main/site'
    u.to_s.should == '/main/site'
  end
  
  it 'should make relative urls absolute' do
    u = Url.parse('/bar')
    u.relative?.should be_true
    Url.default_server = 'irongaze.com'
    u.make_absolute.should == 'http://irongaze.com/bar'
  end
  
  it 'should support ports in absolute URL generation' do
    u = Url.parse('/bar')
    Url.default_server = 'irongaze.com'
    Url.default_port = '3000'
    u.make_absolute.should == 'http://irongaze.com:3000/bar'
  end
  
  it 'should allow explicit servers in make_absolute' do
    u = Url.parse('/bob')
    u.make_absolute(true, 'microsoft.com').should == 'https://microsoft.com/bob'
  end
  
  it 'should escape params correctly' do
    Url.build('/foo', 'one:two' => 'http://other.com').should == '/foo?one%3Atwo=http%3A%2F%2Fother.com'
  end
  
  it 'should allow setting and getting using symbols or strings' do
    u = Url.parse('/')
    u.set_param(:bob, 4)
    u.to_s.should == '/?bob=4'
    u.set_param('bob', 5)
    u.to_s.should == '/?bob=5'
    u.get_param(:bob).should == 5
  end
  
end