role :web, %w{159.203.97.144}
server '159.203.97.144', user: 'sup1', roles: %w{web app}
set :environment, 'ojc_production'

set :ssh_options, {
  keys: %w('~/.ssh/id_rsa.pub'),
  forward_agent: true,
  auth_methods: %w(publickey),
  port: 22,
}
