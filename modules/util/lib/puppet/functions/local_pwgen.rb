require 'securerandom'
require 'openssl'
Puppet::Functions.create_function(:local_pwgen) do
  dispatch :pwgen do
    param 'String', :key
    param 'Integer', :length
  end

  def pwgen(pw_key, length)
    basedir = File.join(Puppet[:vardir],'local_pwgen')
    passfile = File.join(Puppet[:vardir],'local_pwgen','passfile.pass')
    if String($_x_pwgen_hashing_key).length < 16
      if File.readable?(passfile)
        $_x_pwgen_hashing_key = File.read(path)
        $_x_pwgen_hashing_key.gsub!(/\s+/,'')
        if $_x_pwgen_hashing_key.length > 256
          $_x_pwgen_hashing_key = SecureRandom.alphanumeric(64)
          File.write(passfile,$_x_pwgen_hashing_key, mode: "w",)
          File.chmod(0700,passfile)
        end
      end
      FileUtils.mkdir_p basedir
      File.chmod(0700,basedir)
      $_x_pwgen_hashing_key = SecureRandom.alphanumeric(64)
      File.write(passfile,$_x_pwgen_hashing_key,mode: "w", )
      File.chmod(0700,passfile)
    end
    key = Digest::SHA512.digest($_x_pwgen_hashing_key + "aes")
    data = Digest::SHA512.digest($_x_pwgen_hashing_key + pw_key ) + ('p' * (length/2))
    $_x_pwgen_cipher =  OpenSSL::Cipher::AES.new(256,:CBC)
    $_x_pwgen_cipher_enc = $_x_pwgen_cipher.encrypt
    $_x_pwgen_cipher_enc.key = key[0..31]
    $_x_pwgen_cipher_enc.iv = key[32..47]
    encrypted = $_x_pwgen_cipher_enc.update(data) + $_x_pwgen_cipher_enc.final
    out = Base64::urlsafe_encode64(encrypted, padding: false)[1..length]

  end
end