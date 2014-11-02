module Sinatra
  module AlMundo
    module Home
      module StaticPaths

        def get_css_path()
          return request.script_name + "/homepage-css"
        end

        def get_js_path()
          return request.script_name + "/homepage-js"
        end

        def get_img_path()
          return request.script_name + "/homepage-css/images"
        end
        
        def get_font_path()
          return request.script_name + "/homepage-css/fonts"
        end

        def get_files_path()
          return request.script_name + "/homepage-files"
        end

      end
    end
  end
end