threads_count = ENV.fetch('MAX_THREADS') { 5 }.to_i
threads threads_count, threads_count

rackup DefaultRackup
environment ENV.fetch('RACK_ENV') { 'production' }
#environment ENV.fetch('RACK_ENV') { 'development' }

#daemonize true
