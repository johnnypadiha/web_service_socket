# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'web_service_analogico'
set :repo_url, 'git@bitbucket.org:atmatecnologia/web_service_analogico.git'
set :user, 'sup1'
set :port, 22

set :deploy_to, '/var/apps/web_service_analogico'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true
set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :puma_pid,        "#{deploy_to}/tmp/pids/puma.pid"


namespace :deploy do
  task :update do
    invoke 'deploy:stop'
    invoke 'deploy:update_code'
    invoke 'deploy:start'
  end

  task :update_code do
    on roles(:web), in: :sequence, wait: 5 do
      #execute "rm -rf #{deploy_to}/Gemfile.lock"
      execute "cd #{deploy_to} && git stash"
      execute "cd #{deploy_to} && git pull"
      execute "cd #{deploy_to} && bundle install --path vendor/bundle"

      #caso dê erro de log descomenta essas linhas
      #execute "cd #{deploy_to} && mkdir log"
      #execute "cd #{deploy_to} && touch webservice.log"

    end
  end

  task :start do
    on roles(:web) do
      execute "echo > log.log"
      execute "cd #{deploy_to} && bundle exec puma -d -C config/puma.rb"
    end
  end

  task :stop do
    on roles(:web) do
        execute "kill -s SIGUSR2 $(cat #{deploy_to}/tmp/pids/puma.pid)"
        # execute "kill -s SIGUSR2 $(cat #{deploy_to}/tmp/pids/gerente.pid)"
    end
  end

end
