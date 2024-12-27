require 'net_http_unix'
require 'json'

@@messdb_client = NetX::HTTPUnix.new('unix:///run/dpp/dpp.socket')
Puppet::Functions.create_function(:'messdb_write') do
  dispatch :key do
    param 'String', :db_key
    param 'Any', :value
  end
  def key(db_key,value )
    #if !@@messdb_client
    #end
    req = Net::HTTP::Post.new("/api/messdb/k/#{db_key}")
    req.body = JSON.generate(value)

    begin
      resp = @@messdb_client.request(req)
    rescue => error
      Puppet.err("messdb: '#{error}'")
      return
    end
    if resp.code == "200"
      return resp.body
    else
      return nil || default_value
    end
    #return "#{db_key} | #{default_value}"
  end
end