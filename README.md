# Filelock

Heavily tested, but simple filelocking solution using [flock](http://linux.die.net/man/2/flock) command.

## Usage

```ruby
Filelock '/tmp/path/to/lock' do
  # do blocking operation
end
```

You can also pass the timeout for blocking operation (default is 60 seconds):

```ruby
Filelock '/tmp/path/to/lock', :timeout => 10 do
  # do blocking operation
end
```

Note that lock file directory must already exist, and lock file is not removed after unlock.

## FAQ

*Does it support NFS?*

No. You can use more complex [lockfile](https://github.com/ahoward/lockfile) gem if you want to support NFS.

*The code is so short. Why shouln't I just copy-paste it?*

Because even such short code can have issues in future. Although it's heavily tested, you may expect new releases of this gem fixing such bogus behavior (or introducing awesome features).

*How it's different from [lockfile](https://github.com/ahoward/lockfile) gem?*

Lockfile is filelocking solution handling NFS filesystems, based on homemade locking solution. Filelock uses [flock](http://linux.die.net/man/2/flock) UNIX command to handle filelocking on very low level. Also lockfile allows you to specify retry timeout. In case of Ruby's flock command this is hard-cored to 0.1 seconds.

*How it's different from [cleverua-lockfile](https://github.com/cleverua/lockfile) gem?*

Cleverua removes lockfile after unlocking it. Thas has been proven fatal both in my tests and in [filelocking advices from the Internet](http://world.std.com/~swmcd/steven/tech/flock.html). You could try find a way to remove lock file without breaking Filelock tests. I will be glad to accept such pull-request.

## Challenge

Please try to break Filelock in some way (note it doesn't support NFS).

If you show at least one failing test, I'll put your name below:

## License

Filelock is MIT-licensed. You are awesome.
