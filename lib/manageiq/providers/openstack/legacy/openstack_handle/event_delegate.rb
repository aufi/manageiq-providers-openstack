module OpenstackHandle
  class EventDelegate < DelegateClass(Fog::Event::OpenStack)
    include OpenstackHandle::HandledList
    include Vmdb::Logging

    SERVICE_NAME = "Event".freeze

    attr_reader :name

    def initialize(dobj, os_handle, name)
      super(dobj)
      @os_handle = os_handle
      @name      = name
      @proxy     = VMDB::Util.http_proxy_uri(:openstack) || VMDB::Util.http_proxy_uri(:default)
    end
  end
end
