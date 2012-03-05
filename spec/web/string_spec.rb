describe String do
  
  it 'should not be html safe' do
    String.new.should_not be_html_safe
    'bob'.should_not be_html_safe
  end
  
  it 'should become a safe string on calls to #html_safe' do
    'abc'.html_safe.should be_a(HtmlSafeString)
  end
  
  it 'should not change contents on calls to #html_safe' do
    '<span class="fun">'.html_safe.should == '<span class="fun">'
  end
  
end