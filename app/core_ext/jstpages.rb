module Sinatra::JstPages

  class JadeEngine < Engine
    def function() "jade.compile(#{contents.inspect})"; end
  end

  register 'jade', JadeEngine

end
