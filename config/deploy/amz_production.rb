role :web, %w{104.236.115.92}
server '104.236.115.92', user: 'sup1', roles: %w{web app}
set :environment, 'amz_production'

set :ssh_options, {
  keys: %w('~/.ssh/id_rsa.pub'),
  forward_agent: true,
  auth_methods: %w(publickey),
  port: 22,
}
