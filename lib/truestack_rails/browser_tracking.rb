module TruestackRails
  module BrowserTracking
    def  truestack_browser_tracker
      if (TruestackRails::Configuration.environments.include?(Rails.env))
        tc_config = TruestackClient.config

        img_url = URI::HTTP.build(
          :host => TruestackClient.config.host,
          :path => "/api/collector/browser",
          :query => {
            :truestack => {
              :name       => "#{controller_name}##{action_name}"},
            "Truestack-Access-Key" =>  tc_config.key,
            "Truestack-Client-Type" => TruestackClient.create_type_string(tc_config.app_version, tc_config.app_environment)
          }.to_query)

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
      "&truestack[tstart]="+ _truestack_browser_data.tstart.getTime() +
      "&truestack[tend]="  +_truestack_browser_data.tend.getTime());
    newimg.setAttribute("width", "1");
    newimg.setAttribute("height", "1");
    newimg.setAttribute("alt", "");

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
