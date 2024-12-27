require 'open3'

Puppet::Functions.create_function(:'generate_ed25519_keypair') do
  def generate_ed25519_keypair()
    if !File.exist?('/bin/wg')
      Puppet.err("/bin/wg does not exist, not generating key")
      return nil
    end
    priv_key, err, status = Open3.capture3(
      "wg genkey",
      )
    if !status.success?
      raise "something went wrong with privkey generation [#{priv_key}], wg genkey out | #{err}"
    end
    pub_key, err, status = Open3.capture3(
      "wg pubkey",
      :stdin_data => priv_key,
      )
    if !status.success?
      raise "something went wrong with pubkey generation [#{pub_key}], wg pubkey out | #{err}"
    end
    keydata = {
      'pub' => pub_key,
      'priv' => priv_key,
    }
    return keydata
  end
end