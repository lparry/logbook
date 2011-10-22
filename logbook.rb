require 'active_support/core_ext/time/calculations'

class Object
  def tapp
    tap { puts inspect }
  end
end

class Commit < Struct.new(:timestamp, :ref, :author, :message)
end

def authors
  [
    'Ben Hoskings'
  ]
end

def repo_names
  {
    'babushka' => '~/projects/babushka/current',
    'jobs'     => '~/projects/tc/jobs'
  }
end

def commit_list path
  Dir.chdir(File.expand_path(path)) {
    `git log --all --pretty=format:"%at %h '%an' %s"`.chomp
  }.split("\n").map {|line|
    timestamp, ref, author, message = line.scan(/^(\w+) (\w+) \'([^\']+)\' (.*)/).flatten
    Commit.new(Time.at(timestamp.to_i), ref, author, message)
  }
end

def commits
  @commits ||= repo_names.keys.inject({}) {|hsh,name|
    hsh[name] = commit_list(repo_names[name]).select {|commit|
      authors.include? commit.author
    }
    hsh
  }
end

def commits_by_day
  commits.keys.inject(
    Hash.new {|hsh,k| hsh[k] = Hash.new {|hsh,k| hsh[k] = [] } }
  ) {|hsh,name|
    commits[name].each {|commit|
      hsh[commit.timestamp.midnight][name].push commit
    }
    hsh
  }
end

commits_by_day
