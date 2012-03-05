describe Html do
  
  it 'should generate simple HTML' do
    Html.build do |html|
      html.span('hello wwworld')
    end.should == '<span>hello wwworld</span>'
  end
  
  it 'should escape unsafe characters' do
    Html.escape_once('"hi&<guy>"').should == '&quot;hi&amp;&lt;guy&gt;&quot;'
  end
  
  it 'should support comments' do
    Html.build do |html|
      html.comment! 'Important stuff'
      html.h1 'Da header'
    end.should == "<!-- Important stuff -->\n\n<h1>\n  Da header\n</h1>\n"
  end
  
end