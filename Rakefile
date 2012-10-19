# The default, if you just run `rake` in this directory, will list all the available tasks
task :default do
  puts "All available rake tasks"
  system 'rake -T'
end

desc "Start server"
task :s do
  system 'bundle exec foreman start'
end

desc "Start guard"
task :g do
  commander 'guard'
end


# run command(s) and capture SIGINT
def commander(*cmds)
  pids = cmds.map { |cmd| Process.spawn("bundle exec #{cmd}") }

  trap('INT') {
    pids.each { |pid| Process.kill(9, pid) rescue Errno::ESRCH }
    puts '==> Stopped!'
    exit 0
  }
  pids.each { |pid| Process.wait(pid) }
end
