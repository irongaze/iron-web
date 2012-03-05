require File.join(File.dirname(__FILE__), '..', 'spec_helper')

SAMPLE_LIBRARY = {
  :red => '#FF0000',
  :purplish => '#FF20EE',
  :orange => '#F0FF00'
}

describe Color do
  
  it 'should default to white' do
    Color.new.r.should == 255
    Color.new.g.should == 255
    Color.new.b.should == 255
    Color.new.a.should == 255
  end
  
  it 'should convert to string as a web string' do
    Color.parse(1,2,3).to_s.should == '#010203'
  end
  
  it 'should parse web colors' do
    Color.new('#f8019c').should == Color.new(248,1,156)
  end

  it 'should make the global rgb() method available' do
    defined?(:rgb).should be_true
  end
  
  it 'should parse values with rgb()' do
    ['#fa8', Color::BLACK].each do |test|
      rgb(test).should == Color.parse(test)
    end
  end
  
  it 'should support alpha' do
    c = rgb('abc')
    c.a.should == 255
    c.trans?.should be_false
    c.opaque?.should be_true
    c.to_s.should == '#AABBCC'
    
    c.a = 38
    c.a.should == 38
    c.trans?.should be_true
    c.opaque?.should be_false
    c.to_s.should == '#AABBCC26'
  end

  it 'should support a definable callback for symbols' do
    Color.lookup_callback = lambda{|val| SAMPLE_LIBRARY[val]}
    SAMPLE_LIBRARY.each_pair do |k,v|
      rgb(k).should == rgb(v)
    end
    Color.parse(:purplish).should == SAMPLE_LIBRARY[:purplish]
  end

end