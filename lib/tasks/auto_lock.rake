namespace :redmine do
  namespace :timelog_restrict_date do
    desc <<~DESC
      Move the time log lock date forward to the configured billing period close date.

      Run it nightly at midnight from cron, for example:
        0 0 * * * cd /path/to/redmine && bundle exec rake redmine:timelog_restrict_date:auto_lock RAILS_ENV=production

      Optional: DATE=YYYY-MM-DD runs it as if today were that date.
    DESC
    task auto_lock: :environment do
      today = ENV['DATE'].present? ? Date.parse(ENV['DATE']) : Date.today

      run = -> { puts RestrictAutoLock.run!(today) }
      # Send the change email before the process exits instead of queueing
      # it on the in-process async adapter, where it would be lost.
      if Mailer.respond_to?(:with_synched_deliveries)
        Mailer.with_synched_deliveries(&run)
      else
        run.call
      end
    end
  end
end
