class Hyrax < PACKMAN::Package
  version '1.9.7'

  label 'master_package'

  depends_on 'tomcat'
  depends_on 'opendap'
  depends_on 'hyrax_olfs'
  depends_on 'hyrax_bes'
  depends_on 'hyrax_dap_server'
  depends_on 'hyrax_netcdf_handler'
  depends_on 'hyrax_hdf4_handler'
  depends_on 'hyrax_hdf5_handler'
  depends_on 'hyrax_ncml_module'
  depends_on 'hyrax_gateway_module'
  depends_on 'hyrax_fileout_netcdf'
  depends_on 'hyrax_freeform_handler'
  depends_on 'hyrax_xml_handler'
  depends_on 'hyrax_csv_handler'
  depends_on 'hyrax_fits_handler'
  # depends_on 'hyrax_ugrid'

  def start
    # Start Hyrax server.
    # - Start Tomcat server with OLFS app.
    PACKMAN.run "#{PACKMAN.prefix(Tomcat)}/bin/startup.sh"
    # - Start BES server.
    if ENV['USER'] != 'root'
      PACKMAN.run "sudo #{PACKMAN.prefix(Hyrax)}/bin/besctl start"
    else
      PACKMAN.run "#{PACKMAN.prefix(Hyrax)}/bin/besctl start"
    end
  end

  def stop
    # Stop Hyrax server.
    # - Stop BES server.
    if ENV['USER'] != 'root'
      PACKMAN.run "sudo #{PACKMAN.prefix(Hyrax)}/bin/besctl stop"
    else
      PACKMAN.run "#{PACKMAN.prefix(Hyrax)}/bin/besctl stop"
    end
    # - Stop Tomcat server with OLFS app.
    PACKMAN.run "#{PACKMAN.prefix(Tomcat)}/bin/shutdown.sh"
  end

  def status
    # Check Hyrax server status.
    # - Check Tomcat server.
    port = File.open("#{PACKMAN.prefix(Tomcat)}/conf/server.xml", 'r').read.match(/<Connector port="(\d+)"/)[1].to_i
    if not PACKMAN::NetworkManager.is_port_open? 'localhost', port
      PACKMAN::CLI.report_warning "#{PACKMAN::CLI.red 'Tomcat'} is not listening on port #{PACKMAN::CLI.red port}."
      return :off
    end
    # - Check BES server.
    res = `#{PACKMAN.prefix(Hyrax)}/bin/besctl status`
    if res =~ /Could not find the BES PID file/
      PACKMAN::CLI.report_warning "#{PACKMAN::CLI.red 'Hyrax BES'} is not working."
      return :off
    end
    return :on
  end
end