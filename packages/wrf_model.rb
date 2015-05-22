class Wrf_model < PACKMAN::Package
  url 'http://www2.mmm.ucar.edu/wrf/src/WRFV3.6.1.TAR.gz'
  sha1 '21b398124041b9e459061605317c4870711634a0'
  version '3.6.1'

  history_version '3.5.1' do
    url 'http://www2.mmm.ucar.edu/wrf/src/WRFV3.5.1.TAR.gz'
    sha1 '4a1ef9569afe02f588a5d4423a7f4a458803d9cc'
  end

  label :installed_with_source

  belongs_to 'wrf'

  option 'build_type' => 'serial'
  option 'use_mpi' => [:package_name, :boolean]
  option 'use_nest' => 0
  option 'run_case' => 'em_real'
  option 'with_chem' => false
  if build_type == 'dmpar' or build_type == 'dm+sm'
    if not use_mpi?
      PACKMAN.report_error "MPI library needs to be specified with "+
        "#{PACKMAN.red '-use_mpi=...'} option when building parallel WRF!"
    end
  elsif build_type == 'serial' or build_type == 'smpar'
    if use_mpi?
      PACKMAN.report_error "MPI library should not be specified when building serial WRF!"
    end
  end

  attach 'chem' do
    url 'http://www2.mmm.ucar.edu/wrf/src/WRFV3-Chem-3.6.1.TAR.gz'
    sha1 '72b56c7e76e8251f9bbbd1d2b95b367ad7d4434b'
    version '3.6.1'
  end

  depends_on 'netcdf'
  depends_on mpi if use_mpi?

  def decompress_to target_dir
    PACKMAN.mkdir target_dir
    PACKMAN.work_in target_dir do
      PACKMAN.decompress package_path
      PACKMAN.work_in 'WRFV3' do
        if with_chem?
          PACKMAN.decompress chem.package_path
        end
      end
    end
  end

  def install
    # Prefix WRF due to some bugs.
    if version == '3.6.1'
      if build_type == 'serial' or build_type == 'smpar'
        PACKMAN.replace 'WRFV3/share/mediation_feedback_domain.F', {
          /(USE module_dm), only: local_communicator/ => '\1'
        }
      end
    end
    # Set compilation environment.
    PACKMAN.append_env 'CURL_PATH', Curl.prefix
    PACKMAN.append_env 'ZLIB_PATH', Zlib.prefix
    PACKMAN.append_env 'HDF5_PATH', Hdf5.prefix
    PACKMAN.append_env 'NETCDF', Netcdf.prefix
    # Check input parameters.
    if not ['serial', 'smpar', 'dmpar', 'dm+sm'].include? build_type
      PACKMAN.report_error "Invalid build type #{PACKMAN.red build_type}!"
    end
    if not [0, 1, 2, 3].include? use_nest
      PACKMAN.report_error "Invalid nest option #{PACKMAN.red use_nest}!"
    end
    if not ['em_b_wave', 'em_esmf_exp', 'em_fire', 'em_grav2d_x',
            'em_heldsuarez', 'em_hill2d_x', 'em_les', 'em_quarter_ss',
            'em_real', 'em_scm_xy', 'em_seabreeze2d_x', 'em_squall2d_x',
            'em_squall2d_y', 'em_tropical_cyclone', 'exp_real',
            'nmm_real', 'nmm_tropical_cyclone'].include? run_case
      PACKMAN.report_error "Invalid run case #{PACKMAN.red run_case}!"
    end
    PACKMAN.work_in 'WRFV3' do
      # Configure WRF model.
      print "#{PACKMAN.blue '==>'} "
      if PACKMAN::CommandLine.has_option? '-debug'
        print "#{PACKMAN::RunManager.default_command_prefix} ./configure with platform "
      else
        print "./configure with platform "
      end
      PTY.spawn("#{PACKMAN::RunManager.default_command_prefix} ./configure") do |reader, writer, pid|
        output = reader.expect(/Enter selection.*: /)
        writer.print("#{choose_platform output}\n")
        reader.expect(/Compile for nesting.*: /)
        writer.print("#{use_nest}\n")
        PACKMAN.read_eof reader, pid
      end
      if not File.exist? 'configure.wrf'
        PACKMAN.report_error "#{PACKMAN.red 'configure.wrf'} is not generated!"
      end
      PACKMAN.replace 'configure.wrf', {
        /SFC\s*=.*/ => "SFC := $(FC)",
        /SCC\s*=.*/ => "SCC := $(CC)"
      }
      if build_type == 'dmpar' or build_type == 'dm+sm'
        PACKMAN.replace 'configure.wrf', {
          /DM_FC\s*=.*/ => "DM_FC := $(MPIF90)",
          /DM_CC\s*=.*/ => "DM_CC := $(MPICC)"
        }
      end
      # Compile WRF model.
      PACKMAN.run 'export dontask=1 && ./compile', run_case
      # Check if the executables are generated.
      if not File.exist? 'main/wrf.exe'
        PACKMAN.report_error 'Failed to build WRF!'
      end
    end
  end

  def choose_platform output
    build_type_ = build_type == 'dm+sm' ? 'dm\+sm' : build_type
    matched_platform = nil
    if PACKMAN.compiler('c').vendor == 'gnu' and PACKMAN.compiler('fortran').vendor == 'gnu'
      if PACKMAN.compiler('fortran').version <= '4.4.7'
        PACKMAN.report_error "#{PACKMAN.blue 'gfortran'} version "+
          "#{PACKMAN.red PACKMAN.compiler('fortran').version} is too low to build WRF!"
      end
      output.each do |line|
        matched_platform = line.match(/(\d+)\.\s+.*gfortran\s*\w*\s*with gcc\s+\(#{build_type_}\)/)
        PACKMAN.report_error "Mess up with configure output of WRF!" if not matched_platform
      end
    elsif PACKMAN.compiler('c').vendor == 'intel' and PACKMAN.compiler('fortran').vendor == 'intel'
      output.each do |line|
        matched_platform = line.match(/(\d+)\.\s+.*ifort \w* with icc\s+\(#{build_type_}\)/)
        PACKMAN.report_error "Mess up with configure output of WRF!" if not matched_platform
      end
    else
      PACKMAN.report_error 'Unsupported compiler set!'
    end
    print "\"#{PACKMAN.green matched_platform}\"\n"
    return matched_platform[1]
  end
end
