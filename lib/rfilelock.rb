require 'timeout'
require 'filelock/version'
require 'filelock/exec_timeout'
require 'filelock/wait_timeout'
require 'tempfile'


def update_lock_status_in_cache(file, lockname, lock)
  tid = Thread.current.object_id
  file.truncate(0)
  if(lock == true)
    file.write tid
  end
end

def is_owner(lockname)
  tid = Thread.current.object_id
  begin
    file = File.open( lockname, "r")
    ftid = file.read
    file.close
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
        update_lock_status(file, lockname, true)
        Thread.pass until Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) do
          file.flock(File::LOCK_EX)
        end
        rescue Timeout::Error
          update_lock_status(file, lockname, false)
          throw(Timeout::Error)
        end 
        Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) do
          yield file
        end
        rescue Timeout::Error
          update_lock_status(file, lockname, false)
          throw(Timeout::Error)
        end
        update_lock_status(file, lockname, false)
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
        update_lock_status(file, lockname, true)
        Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) do
          file.flock(File::LOCK_EX)
        end
        rescue Timeout::Error
          update_lock_status(file, lockname, false)
          throw(Timeout::Error)
        end
        Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) do
          yield file
        end
        rescue Timeout::Error
          update_lock_status(file, lockname, false)
          throw(Timeout::Error)
        end
        update_lock_status(file, lockname, false)
      end
    end
  end
end
