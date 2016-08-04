require 'yaml'

# Print an error message and stop execution on handled errors
def handle_error(error_msg)
  puts "ERROR: #{error_msg}"
  exit
end

def banner(message)
  puts
  puts "======================================================================"
  puts ">> #{message}"
  puts "======================================================================"
  puts
end

# Verify that config.yaml exists
root_dir = File.dirname(__FILE__)
cfg_yaml_file = "#{root_dir}/config.yaml"
error_msg = "#{cfg_yaml_file} does not exist"
handle_error(error_msg) unless File.exists?(cfg_yaml_file)

cfg_yaml = YAML.load_file(cfg_yaml_file)
error_msg = "#{cfg_yaml_file} exists, but is empty"
handle_error(error_msg) unless cfg_yaml

control_repo = cfg_yaml['control_repo']

repo_dir = File.dirname(__FILE__)

control_dir = cfg_yaml['control_dir']
modules_dir = cfg_yaml['modules_dir']
environment_dir = File.join(root_dir, 'environments')

namespace :init do
  desc "Run bundle install"
  task :bi do
    sh("bundle install")
  end

  desc "Clone the control repository from upstream into #{control_dir}/"
  task :control do
    if Dir.exists?("#{repo_dir}/#{control_dir}/.git")
      puts "It appears the control repository is already cloned."
      puts "(#{repo_dir}/#{control_dir}/.git exists...)"
      puts "Skipping clone..."
    else
      puts "=> Cloning control repository to #{control_dir}"
      sh("git clone #{control_repo} #{repo_dir}/#{control_dir}")
    end
    puts "=> Running 'bundle install' within #{control_dir}..."
    sh("cd #{repo_dir}/#{control_dir} && bundle install")
  end

  desc "Run r10k and populate the environments directory"
  task :r10k do
    puts "=> Running r10k in control"
    puts "=> This populates the \"#{control}\" directory Puppet modules"
    puts "*** This can take several minutes. Please be patient."
    puts
    sh("cd #{repo_dir}/#{control_dir} && bundle exec r10k puppetfile install -v")

    puts "=> Running r10k to deploy environments and modules"
    puts "=> This populates the environments/ directory with environments and modules"
    puts "*** This can take several minutes. Please be patient."
    puts
    FileUtils.mkdir_p(environment_dir) unless Dir.exists?(environment_dir)
    sh("bundle exec r10k deploy environment -pv")
  end

  desc "Copy git hooks to target/.git/hooks/; Uses 'control' by default."
  task :hooks, :target do |t,args|
    args.with_defaults(:target => 'control')
    puts "=> Copying git hooks to #{args[:target]}/.git/hooks/"
    sh("cp -rf #{repo_dir}/.githooks/* #{repo_dir}/#{args[:target]}/.git/hooks")
  end

  desc "Copy Puppet module skeleton/template for 'puppet module generate'"
  task :skel do
    skel_dir = "#{ENV['HOME']}/.puppetlabs/opt/puppet/cache/puppet-module"
    puts "=> Copying Puppet module skeleton"

    FileUtils.mkdir_p(skel_dir) unless Dir.exists?(skel_dir)

    sh("rm -rf #{skel_dir}/skeleton") if Dir.exists?("#{skel_dir}/skeleton")
    sh("cp -rf #{repo_dir}/.module_skeleton/skeleton #{skel_dir}")

    puts "=> Creating hooks directory: #{skel_dir}/skeleton/.git/hooks"
    FileUtils.mkdir_p("#{skel_dir}/skeleton/.git/hooks")
    sh("cp -r #{repo_dir}/.githooks/* #{skel_dir}/skeleton/.git/hooks")
  end

  desc "Provide a basic Vim configuration for Puppet"
  task :vim do
    puts
    puts "NOTE: This will create a ~/.vim_puppet file and use 'Vundler' to"
    puts "      install the related plugins"
    puts
    puts "You can look at the .vim_puppet file to see what's in it and re-run"
    puts "this by executing 'rake init:vim' if you'd like to add it."
    puts
    print "Would you like to add a basic Vim configuration? (y/N) "
    if $stdin.gets.chomp =~ /^y(es)?$/i

      unless Dir.exists?("#{ENV['HOME']}/.vim/bundle/Vundle.vim")
        puts "=> Installing vundle to ~/.vim/bundle/Vundle.vim"
        sh("git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim")
      end

      cp("#{repo_dir}/.vim_puppet", "#{ENV['HOME']}/.vim_puppet")

      vim_lines = [
        '" vundler and puppet; Added by puppet_dev',
        'set nocompatible',
        'set rtp+=~/.vim/bundle/Vundle.vim',
        'call vundle#begin()',
        "Plugin 'gmarik/Vundle.vim'",
        'call vundle#end()',
        "source #{ENV['HOME']}/.vim_puppet"
      ]

      sh("touch #{ENV['HOME']}/.vimrc") unless File.exists?("#{ENV['HOME']}/.vimrc")
      vim_lines.each do |vimline|

        text = File.read("#{ENV['HOME']}/.vimrc")

        unless text =~ /#{Regexp.quote(vimline)}/
          puts "===> Adding #{vimline} to vimrc"
          File.open("#{ENV['HOME']}/.vimrc", 'a') do |file|
            file.write "#{vimline}\n"
          end
        end
      end

      puts "=> Running vim +PluginInstall +qall"
      sh('vim +PluginInstall +qall')

    end
  end

  desc "Configure Git user and email"
  task :gitconfig do
    git_user = %x{git config --global --get user.name}
    git_email = %x{git config --global --get user.email}
    puts "Your current git configuration is set to:"
    puts "   Name: #{git_user}"
    puts "  Email: #{git_email}"
    puts
    print "Would you like to change it? (y/N) "
    if $stdin.gets.chomp =~ /^y(es)?$/i
      print "Name: "
      name = $stdin.gets.chomp
      print "Email: "
      email = $stdin.gets.chomp

      puts
      sh("git config --global user.name '#{name}'")
      sh("git config --global user.email '#{email}'")
      puts
    end

    puts "You can chanage your Git name and e-mail address by using something like:"
    puts "    git config --global user.name 'John Doe'"
    puts "    git config --global user.email 'jdoe@foo'"
    puts "or just run 'rake init:gitconfig' from this directory"
    puts
    puts "Hint: --global will write to ~/.gitconfig"
    puts "Hint: If you want it per-repo, you can omit the --global argument"
    puts
  end
end

desc "Update puppet_dev, control repo, and r10k"
task :update do
  banner("Updating puppet_dev repository...")
  sh("git fetch --all")
  sh("(git checkout master && git pull origin master)")

  banner("Updating control repository...")
  sh("(cd control && git fetch --all)")

  banner("Running r10k")
  FileUtils.mkdir_p(environment_dir) unless Dir.exists?(environment_dir)
  sh("bundle exec r10k deploy environment -pv")
end

desc "Initialize the environment"
task :init do
  banner("Running bundle install")
  Rake::Task['init:bi'].invoke

  banner("Cloning control repository")
  Rake::Task['init:control'].invoke

  banner("Running r10k")
  Rake::Task['init:r10k'].invoke

  banner("Copying Git Hooks")
  Rake::Task['init:hooks'].invoke

  banner("Copying Puppet module skeleton")
  Rake::Task['init:skel'].invoke

  banner("VIM configuration")
  Rake::Task['init:vim'].invoke

  banner("Git configuration")
  Rake::Task['init:gitconfig'].invoke

  Dir.mkdir("#{repo_dir}/#{modules_dir}") unless Dir.exists?("#{repo_dir}/#{modules_dir}")

  puts
  puts "======================================================================"
  puts "Complete!"
  puts
end

