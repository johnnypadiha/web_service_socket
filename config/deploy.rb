# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'web_service_analogico'
set :repo_url, 'git@bitbucket.org:atmatecnologia/web_service_analogico.git'
set :user, 'sup1'
set :port, 22

set :deploy_to, '/var/apps/web_service_analogico'

set :pty, true

set :puma_pid,        "#{deploy_to}/tmp/pids/puma.pid"

namespace :deploy do
  task :update do
    invoke 'deploy:stop'
    invoke 'deploy:update_code'
    # invoke 'deploy:migrate'
    invoke 'deploy:start'
  end

  task :update_code do
    on roles(:web), in: :sequence, wait: 5 do
      execute "cd #{deploy_to} && git stash"
      execute "cd #{deploy_to} && git pull --no-edit"
      execute "cd #{deploy_to} && bundle install --path vendor/bundle"
    end
  end

  # task :migrate do
  #   on roles(:web), in: :sequence, wait: 5 do
  #     execute "cd #{deploy_to} && bundle exec rake db:migrate RAILS_ENV=production"
  #   end
  # end

  task :start do
    on roles(:web) do
      execute "echo > log.log"
      execute "cd #{deploy_to} && bundle exec puma -d -C config/puma.rb -e #{fetch(:environment)}"
    end
  end

  task :stop do
    on roles(:web) do
        execute "kill -s SIGUSR2 $(cat #{deploy_to}/tmp/pids/puma.pid)"
        execute "kill -s SIGUSR2 $(cat #{deploy_to}/tmp/pids/gerente.pid)"
    end
  end

end
