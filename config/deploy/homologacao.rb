role :web, %w{45.55.233.137}
server '45.55.233.137', user: 'sup1', roles: %w{web app}, my_property: :my_value

set :ssh_options, {
  keys: %w('~/.ssh/id_rsa.pub'),
  forward_agent: true,
  auth_methods: %w(publickey),
  port: 22,
}
