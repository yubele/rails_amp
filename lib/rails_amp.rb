require 'rails_amp/version'

if defined?(Rails::Railtie)
  require 'rails_amp/railtie'
else
  raise 'rails_amp is not compatible with Rails 2.* or older'
end

module RailsAmp
  autoload :Config, 'rails_amp/config'

  extend(Module.new {
    # Get RailsAmp configuration object.
    def config
      Thread.current[:rails_amp_config] ||= RailsAmp::Config.new
    end

    # Set RailsAmp configuration object.
    def config=(value)
      Thread.current[:rails_amp_config] = value
    end

    # Write methods which delegates to the configuration object.
    %w( format config_file default_format targets analytics ).each do |method|
      module_eval <<-DELEGATORS, __FILE__, __LINE__ + 1
        def #{method}
          config.#{method}
        end

        def #{method}=(value)
          config.#{method} = (value)
        end
      DELEGATORS
    end

    def disable_all?
      targets.blank?
    end

    def enable_all?
      targets['application'] == 'all'
    end

    def controller_all?(key)
      targets.has_key?(key) && targets[key].blank?
    end

    def controller_actions?(key)
      targets.has_key?(key) && targets[key].present?
    end

    def target_actions(klass)
      return []                        if disable_all?
      return klass.action_methods.to_a if enable_all?
      key = klass_to_key(klass)
      return klass.action_methods.to_a if controller_all?(key)
      return targets[key]              if controller_actions?(key)
      []
    end

    def klass_to_key(klass)
      klass.name.underscore.sub(/_controller\z/, '')
    end

    def key_to_klass(key)
      (key.camelcase + 'Controller').constantize
    end

    def target?(controller)
      target_actions = target_actions( key_to_klass(controller.controller_name) )
      controller.action_name.in?(target_actions)
    end

    def amp_format?
      format == default_format.to_s
    end

    def renderable?(controller)
      amp_format? && target?(controller)
    end
  })
end
