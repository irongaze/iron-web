describe Html::Element do

  # Helper to shortcut a lot of typing...
  def build(*args, &block)
    Html::Element.build(*args, &block)
  end

  it 'should build standard tags' do
    Html::Element.new('b').render.should == '<b></b>'
    Html::Element.build('script').should include('<script></script>')
  end
  
  it 'should build singleton tags' do
    build('img').should == '<img>'
    build('input').should == '<input>'
  end
  
  it 'should build attributes' do
    build('img', :src => '/foo.jpg').should == '<img src="/foo.jpg">'
    build('span', :id => 'alpha', :class => 'bold').should == '<span id="alpha" class="bold"></span>'
  end
  
  it 'should support basic text' do
    build('span', 'heya').should == '<span>heya</span>'
  end
  
  it 'should html escape basic text' do
    build('span', '"boo!"').should == '<span>&quot;boo!&quot;</span>'
  end
  
  it 'should html escape attr values' do 
    build('a', :alt => 'We had "fun"').should == '<a alt="We had &quot;fun&quot;"></a>'
  end
  
  it 'should support indenting' do
    Html::Element.new('div', 'indent!').render.should == "\n<div>\n  indent!\n</div>\n"
  end
  
  it 'should support block indenting by skipping initial newline' do
    Html::Element.new('div', 'indent!').render(0,true).should == "<div>\n  indent!\n</div>\n"
  end
  
  it 'should add attributes when called as setters' do
    span = Html::Element.new(:span)
    span.class = 'dynamic'
    span.class += ' frenetic'
    span.id = 'header'
    span.attrs.keys.should include(:class, :id)
    span.render.should == '<span class="dynamic frenetic" id="header"></span>'
  end
  
  it 'should yield a block for customization on creation' do
    Html::Element.new(:span) {|span|
      span.id = 'fun'
    }.render.should == '<span id="fun"></span>'
  end
  
  it 'should contain HTML' do
    Html::Element.new(:span).html.should be_a(Html)
  end
  
  it 'should allow setting the inner html' do
    span = Html::Element.new(:span)
    span.html = 'some text'
    span.render.should == '<span>some text</span>'
    span.html = Html.new.strong('more text!')
    span.render.should == '<span><strong>more text!</strong></span>'
  end
  
end