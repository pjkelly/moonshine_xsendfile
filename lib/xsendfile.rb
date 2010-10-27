module Xsendfile

  # Define options for this plugin via the <tt>configure</tt> method
  # in your application manifest (none are needed by default):
  #
  #   configure(:xsendfile => {:x_send_file_path => '/some/absolute/path'})
  #
  # Then call the recipe:
  #
  #  recipe :xsendfile
  def xsendfile(options = {})
    package 'apache2-threaded-dev', :ensure => :installed

    exec 'install_xsendfile',
      :cwd => '/tmp',
      :command => [
        'wget http://github.com/nmaier/mod_xsendfile/raw/0.12/mod_xsendfile.c',
        'apxs2 -ci mod_xsendfile.c'
      ].join(' && '),
      :require => package('apache2-threaded-dev'),
      :before => service('apache2'),
      :creates => '/usr/lib/apache2/modules/mod_xsendfile.so'

    conf = ["XSendFile #{ options[:x_send_file] || 'on'}"]
    conf << "XSendFileIgnoreEtag #{options[:x_send_file_ignore_etag] || 'off'}"
    conf << "XSendFileIgnoreLastModified #{options[:x_send_file_ignore_last_modified] || 'off'}"
    conf << "XSendFilePath #{options[:x_send_file_path]}" if options[:x_send_file_path]

    file '/etc/apache2/mods-available/xsendfile.conf',
      :alias => 'xsendfile_conf',
      :content => conf.join("\n"),
      :mode => '644',
      :notify => service('apache2')

    file '/etc/apache2/mods-available/xsendfile.load',
      :alias => 'load_xsendfile',
      :content => 'LoadModule xsendfile_module /usr/lib/apache2/modules/mod_xsendfile.so',
      :mode => '644',
      :require => file('xsendfile_conf'),
      :notify => service('apache2')

   a2enmod 'xsendfile', :require => file('load_xsendfile')
  end

end