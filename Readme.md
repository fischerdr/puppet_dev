# Puppet Development and Testing Environment

## Overview

This repo's purpose is to provide a simple environment for developing and
testing Puppet code, including "control" repository development and component
module development.

Basically, this is just a container repo for the control repository and
individual component modules so that they can share a Vagrant environment that's
configured for testing in various ways.

It's an "all-in-one" testing environment that should suit common needs for
developing a Puppet control repository (e.g. roles, profiles, hieradata, r10k)
_and_ individual component modules.  The idea is to avoid having to make
commits and push somewhere just to test something.  With this, you should be
able to make changes on your local system and immediately test them in a
vagrant instance without involving version control or a master (unless you
want to - you can do that here, too).  It's also a way to avoid having
multiple Vagrant environments just to test various types of Puppet code or
different modules.

Additionally, some "nice to haves" are optionally provided, such as a Puppet
module skeleton (template) for use with `puppet module generate`, a basic
Vim configuration (optional), and some pre-commit hooks for Git to do some
sanity checking.

## Getting Started

#### Prerequisites

1. You'll need Vagrant [http://vagrantup.com](http://vagrantup.com):
   [https://www.vagrantup.com/downloads.html](https://www.vagrantup.com/downloads.html)
2. You'll need VirtualBox. The boxes used here are made for VirtualBox:
   [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
3. You'll need some idea of what a "control" repo and "component modules" are.
   You should also already have a "control repo" on a Git server somewhere.
4. Some knowledge of Git and Puppet

#### 1. Clone this repository

Clone this repository to your system.

For example:

```shell
git clone https://github.com/joshbeard/puppet_dev.git
```

#### 2. Run 'rake init'

From the repo's directory, run:

```shell
rake init
```

This will do the following:

* Clone the control repository to `control/`
* Copy some Git pre-commit hooks into it.
* Run `bundle install` within the control repository to install required Rubygems.
* Run `r10k` to populate its Puppet modules.
* Create a `modules/` directory intended for component modules.
* Copy a Puppet module skeleton (template) to `$HOME/.puppetlabs/opt/puppet/cache/puppet-modules/skeleton` for use with `puppet module generate`
* Setup an `environments/` directory that r10k deploys the Puppet environments from the upstream Git repo to.
* Optionally configure Vim for Puppet development
* Optionally configure your Git name and e-mail address

## Usage

### Control Repository

The Puppet "control" repository will be cloned to `control/`.  This is a
regular clone of the repository, nothing special.

It has a `Gemfile` within it for Ruby dependencies.  The `rake init` task above
should have installed those, but you can also do this manually via:

```shell
cd control
bundle install
```

### Module Development

A `modules/` directory should be created.  This directory is intended for _component
modules_.  Any _component module_ that you're developing/testing should be
here to take advantage of the Vagrant environment's configuration.

You can start module development by using the 'puppet module' tool. A template
is provided so that you can do something like the following within the modules
directory:

```shell
puppet module generate jdoe-foo
```

Modules need to be named/created as "author-module".  This can be an
organization, too, like `megacorp-rsyslog`

### r10k

One of r10k's uses is to provide modules to Puppet environments.  If you want
to add a module to an environment (by adding it to the `Puppetfile`) and would
like to test it in Vagrant, you can do that locally by modifying the `Puppetfile`
in the `control/` repo directory and running r10k locally.  For example:

```shell
bundle exec r10k puppetfile install -v
```

This will synchronize modules listed in the `Puppetfile` to a `modules/`
directory in the control repo.  Don't confuse this with your own `modules/`
directory, which is intended for your own development that you're actively
working on and hasn't been added to the Puppetfile yet.

The `rake init` task did an initial run of this in the `control/` repository.

#### Environments

r10k will also checkout each branch of the control repository to its own
directory to the `environments/` directory.  This will be used by Vagrant hosts
that are provisioned in the 'puppet_dev' environment.

It will parse the `Puppetfile` in each branch to deploy Puppet modules for
each environment as well.

### Vagrant

A Vagrant environment is provided that ties things together to provide a pretty
quick way of testing both control repository development and component module
development.  Additionally, it can be tested against an active Puppet master, if
permitted.

Once you're inside a Vagrant instance, this repository will by mounted to
`/vagrant/` or `c:\vagrant\`

The control repo, its modules directory from r10k, and your own `modules/`
directory will be available here.

During provisioning, Vagrant will configure r10k to use `/vagrant/control` as
its source and run r10k.  This will take some time, as r10k checks out each
branch of the control repository to its own directory under `/etc/puppetlabs/code/environments`,
making them available as Puppet environments that you can run against.

Additionally, it will create a symbolic link from `/vagrant/control` to `/etc/puppetlabs/code/environments/vagrant`
This will allow you to test the current control repository that you have checked
out without requiring any git operations (changes you make to the working tree
will be available real-time to the agent.)

Every 10 minutes, a cron job will re-run r10k.  The Vagrant system's Puppet
environment is set to "vagrant" by default.

You have several options for testing.

__Testing a manifest locally:__

```shell
puppet apply -e 'include profile::something::tested'
```

__Maybe you have a manifest that *declares* resources it needs (e.g. in tests/):__

```shell
puppet apply /my_module/tests/init.pp
```

__You can also run 'puppet agent' against the master:__

```shell
puppet agent -t
```

__You can specify an environment to test against:__

```shell
puppet agent -t --environment foo
```

__You can specify an environment with 'puppet apply', too. This is useful
for testing hiera data, for example:__

```shell
puppet apply -e 'include profile::something' --environment foo
```
## Staying Up to Date

There's a few things to keep up to date with:

* The 'puppet_dev' repository
* The control repository clone
* The Puppet environments (via r10k)

TODO: A rake task to safely do this.

### 1. Updating the puppet_dev repository

This can be reguarily updated by pulling from the upstream repository. For
example, if the remote is called 'origin' (default), you can pull upstream
changes via:

```shell
git pull origin master
```

You can also run `rake init` to initialize any new stuff.

### 2. Updating the control repository

The control repository is updated very frequently.  It can be updated via
normal Git means.

```shell
git fetch [--all]
```

This fetches the remote commits and references, but won't automatically merge
them.

```shell
git pull --all
```

This will pull all upstream references and merge them locally.

Ultimately, it's up to you as to how you want to keep things updated, based
on your own workflow and practices.  If you aren't actually working on Puppet
code, it's probably easiest just to do a `git pull`

### 3. Updating Puppet environments (r10k)

With the 'puppet_dev' clone as your current directory, execute:

```shell
bundle exec r10k deploy environment -pv
```

This should be done reguarily as well, as it will keep your local environments
up to date with upstream.

## Helpful References

### Git

* [git - the simple guide](http://rogerdudler.github.io/git-guide/)
* [git immersion](http://gitimmersion.com)
* [GitHub - Try Git](https://try.github.io/levels/1/challenges/1)
* [Codecademy's Learn Git Course](https://www.codecademy.com/learn/learn-git)
* [Atlassian's Getting Git Right](https://www.atlassian.com/git/)
* [Git Book and Reference (Pro Git)](https://git-scm.com/documentation)

### Vagrant

* [Vagrant Documentation](https://www.vagrantup.com/docs/)
