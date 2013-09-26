module Sidetiq
  module Actor
    def self.included(base)
      base.__send__(:include, Celluloid)
      base.finalizer :sidetiq_finalizer
    end

    def initialize(*args, &block)
      log_call "initialize", :debug

      super

      # Link to Sidekiq::Manager when running in server-mode. In most
      # cases the supervisor is booted before Sidekiq has launched
      # fully, so defer this.
      if Sidekiq.server?
        after(0.1) { link_to_sidekiq_manager }
      end
    end

    private

    def sidetiq_finalizer
      log_call "shutting down ...", :debug
    end

    def link_to_sidekiq_manager
      Sidekiq::CLI.instance.launcher.manager.link(current_actor)
    rescue NoMethodError
      debug "Can't link #{self.class.name}. Sidekiq::Manager not running. Retrying in 5 seconds ..."
      after(5) { link_to_sidekiq_manager }
    end

    def log_call(call, level = :info)
      self.__send__(level, "#{self.class.name} id: #{object_id} #{call}")
    end
  end
end
