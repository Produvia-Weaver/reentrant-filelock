require 'timeout'
require 'filelock/version'
require 'filelock/exec_timeout'
require 'filelock/wait_timeout'
require 'tempfile'


def update_lock_status(file, lock)
  tid = Thread.current.object_id.to_s
  file.truncate(0)
  if(lock == true)
    file.write tid
  end
end

def is_owner(lockname)
  tid = Thread.current.object_id.to_s
  #puts "checking if tid=#{tid} is owner"
  begin
    file = File.open( lockname, "r")
    ftid = file.read
    file.close
    #puts "read ftid=#{ftid} returning #{ftid == tid}"
    return ftid == tid
  rescue
    return false
  end
end



if RUBY_PLATFORM == "java"
  def Filelock(lockname, options = {}, &block)
    if(is_owner(lockname))#reentrant
      yield
    else
      lockname = lockname.path if lockname.is_a?(Tempfile)
      File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
        update_lock_status(file, true)
        begin
          Thread.pass until Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) {file.flock(File::LOCK_EX)}
          Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) {yield file}
        rescue Timeout::Error
          update_lock_status(file, false)
          throw(Timeout::Error)
        end
        update_lock_status(file, false)
      end
    end
  end
else
  def Filelock(lockname, options = {}, &block)
    if(is_owner(lockname))#reentrant
      yield
    else
      lockname = lockname.path if lockname.is_a?(Tempfile)
      File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
        update_lock_status(file, true)
        begin
          Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) {file.flock(File::LOCK_EX)}
          Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) {yield file}
        rescue Timeout::Error
          update_lock_status(file, false)
          throw(Timeout::Error)
        end
        update_lock_status(file, false)
      end
    end
  end
end
