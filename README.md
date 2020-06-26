# apply

Lightweight provisioning tool to apply shell scripts on a local or remote
machine.

## Usage

`push` pushes bash scripts called `unit`s through ssh to execute:

   ./push -v units/update units/sshd units/ssh_authorized_keys root@1.2.3.4
   
Units are processed on the target machine by the `run` script. Each unit executes within its own subshell so no variable leak occurs. Each subshell is run with `set -euo pipefail`. Each subshell also sources the contents of `lib` which defines a few convenience functions.

By writing those unit scripts to be idempotent you can just run them again and again. Units can be aggregated in `group`s, which can themselves reference other groups:

   ./push -v groups/base groups/ruby units/dockerd root@foo.example.com

Finally, you can define `host`s, which are like groups, only they save you some typing to apply units to multiple targets:

   ./apply -v hosts/foo.example.com hosts/bar.example.com
   
The above can be made to process hosts in parallel:

   ./apply -v -p hosts/foo.example.com hosts/bar.example.com

Since `units/`, `groups/`, and `hosts/`, are just directories and files, autocompletion works immediately and you could get creative with shell expansion for arguments.

   ./apply hosts/{foo,bar}.example.com hosts/test.*

## Rationale

At some point in a previous company we had a lot of individual VPSes set up basically the same way. I was sick of internal documentation that listed step-by-step commands intertwined with descriptions and manual actions, and any attempt at puppet or ansible just blew up because it was something else to learn by the team (believe me, I tried, it just wouldn't stick with anyone).

So I created `apply`.

It turned out to be a deceptively simple, down-to-earth experience, immediately accessible, trivially enabled literate coding, and overall extremely useful both to pragmatically set up and maintain those VPSes as well as creating dev environments, or local VMs to test a e.g one-shot unit performing a change or migration.
