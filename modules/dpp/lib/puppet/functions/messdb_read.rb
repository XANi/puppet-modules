require 'net_http_unix'

require 'json'
@@messdb_client = NetX::HTTPUnix.new('unix:///run/dpp/dpp.socket')
Puppet::Functions.create_function(:'messdb_read') do
  dispatch :key do
    param 'String', :db_key
    optional_param 'String', :default_value
  end
  def key(db_key, default_value = nil )
    #if !@@messdb_client
    #end
    req = Net::HTTP::Get.new("/api/messdb/k/#{db_key}")
    begin
      resp = @@messdb_client.request(req)
    rescue => error
      Puppet.err("messdb: '#{error}'")
      return
    end
    if resp.code == "200"
      begin
        return JSON.parse(resp.body)
      rescue => error
        Puppet.err("messdb:err parsing json [#{resp.body}:  '#{error}'")
        return nil || default_value
      end
    else
      return nil || default_value
    end
    #return "#{db_key} | #{default_value}"
  end
end