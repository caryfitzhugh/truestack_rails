module TruestackRails
  module BrowserTracking
    def  truestack_browser_tracker
      img_url = URI.new
      img_url.host = TruestackClient.config.host
      img_url.path = "/app/event"
      img_url.query = {"TrueStack-Access-Key"=>TruestackClient.config.key,
                       "type" => 'browser'}
      return <<JS
<script>
var _truestack_browser_data = {
  tstart: new Date(),
  tloaded: null,
  tready:   null,
  old_onload: window.onload
};

window.onload = function() {
  _truestack_browser_data.tloaded = new Date();
  _truestack_browser_data.old_onload();
  _truestack_browser_data.tready = new Date();

  document.write("<img src='#{img_url}&type=browser&'/>");
}


</script>
JS
    end
  end
end
