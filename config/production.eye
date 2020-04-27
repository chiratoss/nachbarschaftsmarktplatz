dir = ENV['RBENV_DIR'] || ENV['PWD'] || File.expand_path(".")
rails_env = ENV['RAILS_ENV'] || 'production'

# Eye self-configuration section
Eye.config do
  logger "#{dir}/log/eye.log"
end

Eye.application 'nama-prod' do
  working_dir dir

  group 'sidekiq' do
    1.times do |i|
      process "sidekiq#{i}" do

        _pidfile = "#{dir}/tmp/pids/sidekiq#{i}.pid"
        pid_file _pidfile
        stdall 'log/trash.log'
        daemonize true

        start_command "bundle exec sidekiq -e #{rails_env} -P #{_pidfile} -L #{dir}/log/sidekiq.log -C #{dir}/config/sidekiq.yml -i #{i}"
        stop_command "bundle exec sidekiqctl stop #{_pidfile}"

        start_timeout 60.seconds
        start_grace 60.seconds
        stop_timeout 60.seconds
        stop_grace 3.minutes
        restart_grace 4.minutes

        #check :cpu, every: 10.seconds, below: 5, times: 3
        check :memory, every: 30.seconds, below: 900.megabytes, times: [2,3]
        #check :runtime, every: 10.minutes, below: 12.hours

      end
    end
  end
end
