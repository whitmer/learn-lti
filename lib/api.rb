
class Api
  def initialize(host, token) 
    @host = host
    @token = token
  end
  
  attr_accessor :host
  attr_accessor :token
  
  def self.get(endpoint, host, token)
    Api.new(host, token).get(endpoint)
  end
  
  def get(endpoint)
    raise "missing token" unless @token
    raise "missing host" unless @host
    endpoint += (endpoint.match(/\?/) ? "&" : "?") + "access_token=" + @token
    puts "API GET: #{@host + endpoint}"
    uri = URI.parse(@host + endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)
    json = ArrayWithPagination.new(json) if json.is_a?(Array)
    if response['link'] && json.is_a?(Array)
      json.link = response['link']
      json.next_url = response['link'].split(/,/).detect{|rel| rel.match(/rel="next"/) }.split(/;/).first.strip[1..-2] rescue nil
    end
    json
  end
  
  def delete(endpoint)
    endpoint += (endpoint.match(/\?/) ? "&" : "?") + "access_token=" + @token
    uri = URI.parse(@host + endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Delete.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)
  end
  
  def post(endpoint, params={})
    endpoint += (endpoint.match(/\?/) ? "&" : "?") + "access_token=" + @token
    uri = URI.parse(@host + endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(params)
    response = http.request(request)
    json = JSON.parse(response.body)
  end
end


class ArrayWithPagination < Array
  attr_accessor :next_url
  attr_accessor :link
end
