require 'active_support/core_ext/time/calculations'
require 'term/ansicolor'

class Object
  def tapp
    tap { puts inspect }
  end
end

class String
  include Term::ANSIColor
end

class Commit < Struct.new(:timestamp, :ref, :author, :message)
end

def authors
  [
    default_name
  ]
end

# The git user name specified in ~/.gitconfig
def default_name
  @default_name ||= `git config --get user.name`
end

def repo_names
  {
    'babushka' => '~/projects/babushka/current',
    'my deps'  => '~/.babushka/deps',
    'tc'       => '~/projects/tc/current',
    'mobwrite' => '~/projects/tc/mobwrite',
    'jobs'     => '~/projects/tc/jobs',
    'dw'       => '~/projects/tc/dw',
    'tc deps'  => '~/projects/tc/babushka-deps',
    'corkboard' => '~/projects/corkboard/current'
  }
end

def coloured key
  colour_names = %w[blue cyan green magenta red yellow]
  @colours ||= {}
  @colours[key.strip] ||= colour_names[@colours.length % colour_names.length]
  Term::ANSIColor.send @colours[key.strip], key
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
  @commits_by_day ||= commits.keys.inject(
    Hash.new {|hsh,k| hsh[k] = Hash.new {|hsh,k| hsh[k] = [] } }
  ) {|hsh,name|
    commits[name].each {|commit|
      hsh[commit.timestamp.midnight][name].push commit
    }
    hsh
  }
end

def print_day day, projects
  puts day.strftime("%a %b %e %Y")
  project_col = projects.keys.map(&:length).max
  projects.each_pair {|project,commits|
    commits.each {|commit|
      puts "    [#{coloured(project.ljust(project_col))}] #{commit.ref} #{commit.message}"
    }
  }
end

def month_index month_name
  %w[
    january february march april may june july august september october november december
  ].index {|m|
    m[month_name]
  }.tap {|index|
    raise "#{month_name} isn't a valid month" unless index
  } + 1
end

def days_to_show
  if ARGV.any?
    month = month_index(ARGV.first)
    year = (Time.now.year - (month > Time.now.month ? 1 : 0))
    commits_by_day.keys.select {|time|
      time.month == month && time.year == year
    }
  else
    commits_by_day.keys
  end.sort
end

days_to_show.each {|day|
  print_day day, commits_by_day[day]
  puts "\n\n"
}
