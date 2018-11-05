require 'timeout'
require 'filelock/version'
require 'filelock/exec_timeout'
require 'filelock/wait_timeout'
require 'tempfile'


def update_lock_status_in_cache(lockname, lock)
  tid = Thread.current.object_id
  locks = $redis.get("reentrant_filelocks")
  if(locks.nil?)
    locks = "{}"
  end
  locks_hash = JSON.parse(locks)
  if(lock)
    locks_hash[lockname]  = tid
  else
    locks_hash.delete(lockname)
  end
  $redis.set("reentrant_filelocks", locks_hash.to_json)
end

def is_owner(lockname)
  tid = Thread.current.object_id
  locks = $redis.get("reentrant_filelocks")
  if(locks.nil?)
    return false
  end
  locks_hash = JSON.parse(locks)
  return (locks_hash[lockname] == tid)
end



if RUBY_PLATFORM == "java"
  def Filelock(lockname, options = {}, &block)
    if(is_owner(lockname))#reentrant
      yield
    else
      lockname = lockname.path if lockname.is_a?(Tempfile)
      File.open(lockname, File::RDWR|File::CREAT, 0644) do |file|
        update_lock_status_in_cache(lockname, true)
        Thread.pass until Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) do
          file.flock(File::LOCK_EX)
        end
        rescue Timeout::Error
          update_lock_status_in_cache(lockname, false)
          throw(Timeout::Error)
        end 
        Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) do
          yield file
        end
        rescue Timeout::Error
          update_lock_status_in_cache(lockname, false)
          throw(Timeout::Error)
        end
        update_lock_status_in_cache(lockname, false)
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
        update_lock_status_in_cache(lockname, true)
        Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) do
          file.flock(File::LOCK_EX)
        end
        rescue Timeout::Error
          update_lock_status_in_cache(lockname, false)
          throw(Timeout::Error)
        end
        Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) do
          yield file
        end
        rescue Timeout::Error
          update_lock_status_in_cache(lockname, false)
          throw(Timeout::Error)
        end
        update_lock_status_in_cache(lockname, false)
      end
    end
  end
end
