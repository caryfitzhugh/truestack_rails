module TruestackRails
  module BrowserTracking
    def  truestack_browser_tracker
      if TruestackRails::Configuration.enable_browser_tracking?
        img_url = URI.parse(TruestackRails::Configuration.host)
        img_url.path = "/app/browser_event"
        img_url.query = {
          :tstart     => TruestackClient.to_timestamp(Time.now),
          :action     => @truestack_request_id,
          :name       => "#{controller_name}##{action_name}",
          "TrueStack-Access-Key" =>  TruestackRails::Configuration.key
        }.to_query

        return <<JS
  <script>
  // Truestack.com
  // Greenfrylabs.com
  // 2012

  var _truestack_browser_data = {
    tstart: new Date(),
    tend:   null,
    existing_onload: window.onload
  };

  window.onload = function() {
    if (_truestack_browser_data.existing_onload) {
      _truestack_browser_data.existing_onload();
    }
    _truestack_browser_data.tend = new Date();

    var newimg = document.createElement('img');
    newimg.setAttribute("style", "height:1px; width:1px");
    newimg.setAttribute("src","#{img_url}"+
      "&tstart="+ _truestack_browser_data.tstart.getTime() / 1000.0+
      "&tend="  +_truestack_browser_data.tend.getTime() / 1000.0);

    document.body.appendChild(newimg);
  }
  </script>
JS
      else
        # Return Nothing
        ''
      end
    end
  end
end
