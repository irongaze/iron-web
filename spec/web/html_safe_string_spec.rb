# Don't run specs if HtmlSafeString is not present, eg when running in a rails environment
if defined?(HtmlSafeString)

describe HtmlSafeString do
  
  it 'should be html safe at creation' do
    HtmlSafeString.new.should be_html_safe
  end
  
  it 'should stay html safe after concatenation' do
    s = HtmlSafeString.new('alpha')
    s += 'beta'
    s.should == 'alphabeta'
    s.should be_html_safe
  end
  
  it 'should safely escape dangerous chars on concatenation' do
    s = HtmlSafeString.new('alpha')
    s += 'b&ta'
    s.should == 'alphab&amp;ta'
  end
  
end

end