module ManageIQ::Providers::Openstack::CloudManager::Vm::OpenscapScan
  extend ActiveSupport::Concern

  included do
#    supports :openscap_scan do
#      supports? :smartstate_analysis
#    end
  end

  def perform_openscap_scan(xccdf_path = "/usr/share/xml/scap/ssg/content/ssg-fedora-xccdf.xml")
    puts "========OSCAP=========="
    ost = OpenStruct.new
    require 'OpenStackExtract/MiqOpenStackVm/MiqOpenStackInstance'
    require 'openscap'

    _log.debug "instance_id = #{ems_ref}"
    ost.scanTime = Time.now.utc unless ost.scanTime

    ems = ext_management_system
    os_handle = ems.openstack_handle

    begin
      miq_vm = MiqOpenStackInstance.new(ems_ref, os_handle)
      p miq_vm

      #miq_vm.create_evm_snapshot(description: "oscap snapshot #{name} #{ost.scanTime}", desc: ost.scanTime)
        #miq_vm.create_snapshot(name: "OpenScap Scan Snapshot #{name}", desc: ost.scanTime)

      extractor = MIQExtract.new(miq_vm, ost)
      #p extractor.rootVolume  # other volumes?
      #cbinding.pry
      snapshot_file_path = extractor.systemFs.rootVolume.dInfo.fileName
      snapshot_name = "miq_oscap_" + snapshot_file_path.gsub("/", "")
      `sudo mkdir -p /mnt/#{snapshot_name}`
      `sudo guestmount -a #{snapshot_file_path} -ir /mnt/#{snapshot_name}`
      ENV['OSCAP_PROBE_ROOT'] = "/mnt/#{snapshot_name}"
      s = OpenSCAP::Xccdf::Session.new(xccdf_path)
      s.load
      s.profile = "common"
      #s.evaluate
      # TODO: handle errors (stderr) and store it into db to show to user
      #s.export_results(:rds_file => "results.rds.xml")
      binding.pry

    ensure
      `sudo guestunmount /dev/#{snapshot_name}` if snapshot_name
      # TODO: delete mnt dir /mnt/ snapshot_name
      miq_vm.unmount if miq_vm
      s.destroy if s
    end

    ost
  end
end
