module RestrictTimeEntryPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      validate :check_restrict_date
    end
  end

  module InstanceMethods

    def check_restrict_date
      if self.spent_on.to_date <= Setting.plugin_redmine_timelog_restrict_date['lock_date'].to_date
        errors.add(:base, "You have missed the time log deadline. Please contact your manager.")
        return
      end
    end      
  end # module InstanceMethods
end # module MultiSenderMailerPatch

# Add module to Mailer class
TimeEntry.send(:include, RestrictTimeEntryPatch)
