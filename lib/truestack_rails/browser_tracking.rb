module TruestackRails
  module BrowserTracking
    def  truestack_browser_tracker
      img_url = URI.parse(TruestackClient.config.host)
      img_url.path = "/app/event"
      img_url.query = "TrueStack-Access-Key=#{TruestackClient.config.key}&type=browser"
      return <<JS
<script>
// Truestack.com
// Greenfrylabs.com
// 2012

var _truestack_browser_data = {
  tstart: new Date(),
  tloaded: null,
  tready:   null,
  old_onload: window.onload
};

window.onload = function() {
  _truestack_browser_data.tloaded = new Date();
  if (_truestack_browser_data.old_onload) {
    _truestack_browser_data.old_onload();
  }
  _truestack_browser_data.tready = new Date();

  var newimg = document.createElement('img');
  newimg.setAttribute("style", "height:1px; width:1px");
  newimg.setAttribute("src","#{img_url}&tstart="+_truestack_browser_data.tstart+"&tloaded="+_truestack_browser_data.tloaded+"&tready="+_truestack_browser_data.tready);

  document.body.appendChild(newimg);
}


</script>
JS
    end
  end
end
