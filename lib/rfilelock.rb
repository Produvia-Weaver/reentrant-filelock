
require 'timeout'
require 'filelock/version'
require 'filelock/exec_timeout'
require 'filelock/wait_timeout'
require 'tempfile'



def update_lock_status(file, lock)
  tid = Thread.current.object_id.to_s
  #puts "updating lock to #{lock} for #{tid}"

  keyfile = File.open( "keyfile.tmp", "w")
  keyfile.truncate(0)
  
  if(lock == true)
    keyfile.write tid
    keyfile.flush
    keyfile.close
  end
end

def is_owner(lockname)
  tid = Thread.current.object_id.to_s
  #puts "checking if tid=#{tid} is owner"
  begin
    ftid = nil
    keyfile = File.open( "keyfile.tmp", "r")
    ftid = keyfile.read
    keyfile.close
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
        Thread.pass until Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) {file.flock(File::LOCK_EX)}
        Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) {
          begin
            update_lock_status(file, true)
            yield file
          rescue Timeout::Error
            update_lock_status(file, false)
            throw(Timeout::Error)
          end
          update_lock_status(file, false)
        }
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
        #puts "trying to lock"
        Timeout::timeout(options.fetch(:wait, 60*60*24), Filelock::WaitTimeout) {file.flock(File::LOCK_EX)}
        Timeout::timeout(options.fetch(:timeout, 60), Filelock::ExecTimeout) {
          begin
            update_lock_status(file, true)
            #puts "locked"
            yield file
            #puts "done"
          rescue Timeout::Error
            update_lock_status(file, false)
            throw(Timeout::Error)
          end
          update_lock_status(file, false)
          
        }
      end
    end
  end
end
