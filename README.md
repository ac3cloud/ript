Ript
====

Ript provides a clean Ruby DSL for describing firewall rules, and implements
database migrations-like functionality for applying the rules with zero downtime.

Ript works with `iptables` on Linux, and is written in Ruby.

Installing
----------

Make sure you have Ruby 1.9.2 installed, and run:

``` bash
gem install ript
```

If you want the firewall rules to be reloaded at reboot, you will need to set up an
init script.

``` bash
sudo cp "$(dirname $(dirname $(dirname $(gem which ript/dsl.rb))))"/dist/init.d /etc/init.d/ript
sudo update-rc.d ript defaults
sudo mkdir /var/lib/ript
sudo chown root.adm /var/lib/ript
sudo chmod 770 /var/lib/ript
```

Applying rules
--------------

 - Run `ript rules generate <path>` - will output all the generated rules by interpreting the file, or files in directory, `<path>`
 - Run `ript rules diff <path>` - will output a diff of rules to apply based on what rules are currently loaded in memory
 - Run `ript rules apply <path>` - will apply the aforementioned diff
 - Run `ript rules diff <path>` - will display any rules not applied correctly
 - Run `ript rules save` - will output the currently loaded rule in iptables-restore format
 - Run `ript clean diff <path>` - will output iptables commands to delete unneeded rules
 - Run `ript clean apply <path>` - will run the iptables commands to delete unneeded rules

There are tests for this workflow in `features/cli.feature`

Note: If you are using the supplied init script then you will need to add:
``` bash
ript rules save > /var/lib/ript/iptables.stat
```
to your workflow.

Developing
----------

It is recommended to use a Ubuntu Lucid VM to develop Ript. If you develop on a machine without iptables some of the tests will fail.

It is also recommended that you use [rbenv](http://rbenv.org/).

``` bash
rbenv install 1.9.2-p290
gem install bundler
rbenv rehash
```

Then to setup a Ript development environment, run:

``` bash
git clone git@github.com:bulletproofnetworks/ript.git
cd ript
bundle
rbenv rehash
```

Then run the tests with:

``` bash
# Run all the tests
sudo bin/rbenv-sudo rake features
# Run a specific test file
sudo bin/rbenv-sudo cucumber -r features/support/ -r features/step_definitions/ features/dsl/filter.feature
# Run a specific test in a file
sudo bin/rbenv-sudo cucumber -r features/support/ -r features/step_definitions/ features/dsl/filter.feature:13
```

ript commands can be run like so:

```` bash
sudo bin/rbenv-sudo bundle exec ript --help
```

Releasing
---------

1. Bump the version in `lib/ript/version.rb`
2. Add an entry to `CHANGELOG.md`
3. Run a `bundle` to update any RubyGems dependencies.
4. `git commit` everything.
5. git tag the version git tag X.Y.Z
6. Build the gem with `rake build`

This will build a `.gem` and a `.deb` in `pkg/`

Design
------

 - Applying firewall rules should cause zero downtime.
 - Making a change to a partition's rules should only ever affect that partition.
 - Each partition has their own set of chains where their rules live.
 - Each chain is self contained, and there a pointers to that chain from a
   global chain where all partition pointers live.
 - The pointer rules should be kept very simple, to reduce the chain traversal
   time for packets.
 - Rolling forward is as simple as creating a new chain, and inserting pointers
   to the new chain in the global chain.
 - Rolling back is as simple as deleting the pointers to the new chain from the
   global chain. The new chain could be retained, but we choose delete it.
 - Decommissioning a partition should be as simple as removing the partition's
   rules file.
 - Deleting the rules file will cause Ript to realise the partition's chains
   should be deleted.

The DSL
-------

The core of Ript is its easy to use DSL to describe iptables firewall rules.

The DSL is flexible and handles both simple and complex use cases.

### Introduction ###

![Book cover - http://www.flickr.com/photos/sterlic/4299631538/sizes/z/in/photostream/](http://farm5.staticflickr.com/4116/4880818306_3bd230d0d4_z.jpg)

Let's start from the beginning:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  # Labels + rules go here
end
```

All labels + rules in Ript are wrapped in a `partition` block, which partitions
partition rules so they can be changed on a per-partition basis. This is integral
to how Ript does zero-downtime rule migrations.

So, what are labels?

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "api.joeblogsco.com", :address => "172.19.56.217"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"
end
```

Labels are identifiers for addresses or subnets that you want to write rules
for.

What are rules?

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "api.joeblogsco.com", :address => "172.19.56.217"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"

  rewrite "public website" do
    ports 80
    dnat  "www.joeblogsco.com" => "app-01"
  end
end
```

Rules define how traffic flows from one place to another. Rules can either
rewrite the source or destination of a packet (SNAT and DNAT), or permit/deny
the flow of traffic:


``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "api.joeblogsco.com", :address => "172.19.56.217"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"
  label "trusted office",     :address => "172.20.4.124"

  rewrite "public website" do
    ports 80
    dnat  "www.joeblogsco.com" => "app-01"
  end

  rewrite "public ssh access" do
    ports 22
    dnat  "www.joeblogsco.com" => "app-01"
  end

end
```

In the above example, we are telling Ript we want SSH traffic to
`www.joeblogsco.co` (`172.19.56.216`) which is on a public network to be sent
to `app-01` (`192.168.5.230`), which is on a private network.

Because the default policy is to drop packets that don't have an explicit
match, we also need an `accept` rule so that the traffic being rewritten is also
allowed to pass through.

Ript knows this is generally what you want to do, so it actually creates this
rule for you automatically. If we were to write it out, it would look something
like this:

``` ruby
rewrite "public ssh access" do
  ports 22
  dnat  "www.joeblogsco.com" => "app-01"
end

accept "allow public ssh access" do
  protocols "tcp"
  ports     22
  to        "www.joeblogsco.com"
end
```

Ript's DSL is actually pretty smart, so we can clean up the above example a
bit:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "api.joeblogsco.com", :address => "172.19.56.217"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"
  label "trusted office",     :address => "172.20.4.124"

  rewrite "public website + ssh access" do
    ports 80, 22
    dnat  "www.joeblogsco.com" => "app-01"
  end

end
```

Here we have collapsed the two rewrite rules into one. Ript does the heavy
lifting behind the scenes to generate the all the rules.

If you want to be more specific about your rewrites (for example, you only want
external SSH access from a specific jump host), it's really straight forward:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "api.joeblogsco.com", :address => "172.19.56.217"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"
  label "trusted office",     :address => "172.20.4.124"

  rewrite "public website" do
    ports 80
    dnat  "www.joeblogsco.com" => "app-01"
  end

  rewrite "trusted ssh access" do
    ports 22
    from "trusted office"
    dnat  "www.joeblogsco.com" => "app-01"
  end
end
```

<a id="ports"></a>
You have a lot of flexibility when specifying ports, port ranges, and port mappings:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "api.joeblogsco.com", :address => "172.19.56.217"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"
  label "app-02",             :address => "192.168.5.231"
  label "trusted office",     :address => "172.20.4.124"

  rewrite "public mail" do
    # Pass TCP port 25 + 993 through to app-01
    ports 25, 993
    dnat  "www.joeblogsco.com" => "app-01"
  end

  rewrite "trusted private services" do
    # Pass TCP port 6000 to 8000 through to app-01 from the trusted office
    from "trusted office"
    ports 6000..8000
    dnat  "www.joeblogsco.com" => "app-01"
  end

  rewrite "public website" do
    # Map TCP port 80 traffic on the public IP to TCP port 8080 on app-01
    ports 80 => 8080
    dnat  "www.joeblogsco.com" => "app-01"
  end

  rewrite "api services" do
    # Pass TCP port 80 through to app-02
    # Pass TCP port 8000 to 8900 through to app-02
    # Map TCP port 2222 traffic on the public IP to TCP port 22 on app-02
    ports 80, 8000..8900, 2222 => 22
    dnat  "api.joeblogsco.com" => "app-02"
  end
end
```

The above `ports` syntax works throughout all rule types.

Some notes on the DSL so far:

 - A label's scope is restricted to the partition block it is defined in. This
   means you can use the same labels across different partitions and there won't
   be naming colissions.

 - The string argument passed to `rewrite`, `accept`, and other DSL rules is
   used purely for documentation (think comments). Other people maintaining your
   firewall rules will love you when you describe the intention of those rule in
   these comments.

   It's always best to write rules as if the person who ends up maintaining your
   rules is a violent psychopath who knows where you live.

 - Rules will default to the TCP protocol if you don't specify one. Valid
   protocols can be found in `/etc/protocols` on any Linux system. Ript accepts
   both the numeric and string identifiers (`udp` and `17` are both valid), but
   strongly recommends you use the string identifiers.

 - Given `accept` rules are created automatically when you define a rewrite, you
   may be wondering if `accept` rules are used at all?

   `accept` is very useful on standalone firewalls, when opening up specific
   ports to the public internet.

   For firewall configurations that are doing lots of public-to-private address
   translation, you're going to use `accepts` very rarely.

 - Arguments to `ports` can be mixed (`ports 500..650, 80, 25, 9000..9500`),
   but you must always specify port mappings last, e.g. `ports 25, 80 => 8080`
   is valid, but `ports 80 => 8080, 25` is not.


### Rule types ###

![Ruler - http://www.flickr.com/photos/sterlic/4299631538/](http://farm3.staticflickr.com/2730/4299631538_220c9c9448_z.jpg)

The introduction examples cover the common use cases, but Ript has support for
many other types of rules.

For example, SNAT:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "joeblogsco subnet",  :address => "192.168.5.224/27"
  label "app-01",             :address => "192.168.5.230"

  rewrite "private to public" do
    snat "joeblogsco subnet" => "www.joeblogsco.com"
  end
end
```

The above SNAT rule will rewrite all outgoing traffic from the
`joeblogsco subnet` to appear as if it's originating from `www.joeblogsco.com`
(`172.19.56.216`).

If you need to explicitly drop traffic from somewhere, Ript makes this trivial:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "app-01",             :address => "192.168.5.230"
  label "bad guy",            :address => "172.19.110.247"

  rewrite "public website + ssh access" do
    ports 80, 22
    dnat  "www.joeblogsco.com" => "app-01"
  end

  drop "bad guy" do
    from "bad guy"
    to   "www.joeblogsco.com"
  end
end
```

You can also broaden your drop to subnets, and restrict it down to a protocol:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "app-01",             :address => "192.168.5.230"
  label "bad guys",           :address => "10.0.0.0/8"

  rewrite "public website + ssh access" do
    ports 80, 22
    dnat  "www.joeblogsco.com" => "app-01"
  end

  drop "bad guys" do
    protocols "udp"
    from      "bad guys"
    to        "www.joeblogsco.com"
  end
end
```

Alternatively, you can also reject the traffic:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "app-01",             :address => "192.168.5.230"
  label "bad guys",           :address => "10.0.0.0/8"

  rewrite "public website + ssh access" do
    ports 80, 22
    dnat  "www.joeblogsco.com" => "app-01"
  end

  reject "bad guys" do
    protocols "udp"
    from      "bad guys"
    to        "www.joeblogsco.com"
  end
end
```

### Logging ###

![Logs - http://www.flickr.com/photos/crawshawt/4636162605/](http://farm5.staticflickr.com/4020/4636162605_9ac8e91b56_z.jpg)

Dropping and rejecting traffic is very useful, but if a tree falls in the
forest and no-one is there to hear it...

Ript makes flipping on logging extremely simple:

``` ruby
# partitions/joeblogsco.rb
partition "joeblogsco" do
  label "www.joeblogsco.com", :address => "172.19.56.216"
  label "app-01",             :address => "192.168.5.230"
  label "bad guys",           :address => "10.0.0.0/8"

  rewrite "public website + ssh access", :log => true do
    ports 80, 22
    dnat  "www.joeblogsco.com" => "app-01"
  end

  reject "bad guys", :log => true do
    protocols "udp"
    from      "bad guys"
    to        "www.joeblogsco.com"
  end
end
```

You can pass `:log => true` to any rule, and Ript will automatically generate
logging statements.


### Shortcuts ###

![Shorthand http://www.flickr.com/photos/sizemore/2215594186/](http://farm3.staticflickr.com/2397/2215594186_c979f71689_z.jpg)

Ript provides shortcuts for setting up common rules:

``` ruby
partition "joeblogsco" do
  label "joeblogsco uat subnet",   :address => "192.168.5.0/24"
  label "joeblogsco stage subnet", :address => "10.60.2.0/24"
  label "joeblogsco prod subnet",  :address => "10.60.3.0/24"
  label "www.joeblogsco.com",      :address => "172.19.56.216"

  rewrite "private to public" do
    snat  [ "joeblogsco uat subnet",
            "joeblogsco stage subnet",
            "joeblogsco prod subnet"  ] => "www.joeblogsco.com"
  end
end
```

Ript will expand the above to:

``` ruby
partition "joeblogsco" do
  label "joeblogsco uat subnet",   :address => "192.168.5.0/24"
  label "joeblogsco stage subnet", :address => "10.60.2.0/24"
  label "joeblogsco prod subnet",  :address => "10.60.3.0/24"
  label "www.joeblogsco.com",      :address => "172.19.56.216"

  rewrite "private to public" do
    snat "joeblogsco uat subnet" => "www.joeblogsco.com"
  end

  rewrite "private to public" do
    snat "joeblogsco stage subnet" => "www.joeblogsco.com"
  end

  rewrite "private to public" do
    snat "joeblogsco prod subnet" => "www.joeblogsco.com"
  end
end
```

This also behaves exactly the same way with `accept`/`reject`/`drop` rules:

``` ruby
partition "tootyfruity" do
  label "apple",      :address => "192.168.0.1"
  label "blueberry",  :address => "192.168.0.2"
  label "cranberry",  :address => "192.168.0.3"
  label "eggplant",   :address => "192.168.0.4"
  label "fennel",     :address => "192.168.0.5"
  label "grapefruit", :address => "192.168.0.6"

  accept "fruits of the forest" do
    protocols "tcp"
    ports     22
    from      %w(apple blueberry cranberry eggplant fennel grapefruit)
    to        %w(apple blueberry cranberry eggplant fennel grapefruit)
  end
end
```

In the above example, Ript will generate rules for all the different
combinations of `from` + `to` hosts.

You can also specify ranges of ports to generate rules for, and setup port
mappings:

``` ruby
partition "tootyfruity" do
  label "apple",      :address => "192.168.0.1"
  label "blueberry",  :address => "192.168.0.2"
  label "cranberry",  :address => "192.168.0.3"
  label "eggplant",   :address => "192.168.0.4"
  label "fennel",     :address => "192.168.0.5"
  label "grapefruit", :address => "192.168.0.6"

  rewrite "forward lots of ports, and don't make SSH public" do
    protocols "tcp"
    ports     80, 8600..8900, 443 => 4443, 2222 => 22
    from      %w(apple blueberry cranberry eggplant fennel grapefruit)
    to        %w(apple blueberry cranberry eggplant fennel grapefruit)
  end
end
```

The above example will generate a *lot* of rules, but it illustrates the power
of the DSL.
