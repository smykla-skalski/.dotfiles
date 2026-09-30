# Knowledge

## List all `iptables` rules

```sh
# -L | list rules
# -v | verbose output
# -n | numeric output for IP addresses and ports
iptables -L -v -n
```

## Ignore path in git repository without adding it to the `.gitignore` file

You can add the path (glob patterns allowed) in the `.git/info/exclude` file in a repository

```sh
echo "tmp/*.go" >> .git/info/exclude
```

## Clean all kuma/kong-mesh resources except the kong-mesh-license secret if present

```sh
resources="endpointslice,replicaset,mutatingwebhookconfiguration,validatingwebhookconfiguration"
resources="$resources,configmap,secret,crd,svc,clusterrole,clusterrolebinding"
resources="$resources,role,rolebinding,deploy,serviceaccount,ingress"
kubectl get "$resources" -A -o json \
  | jq -r '.items[]
    | select(.metadata.name | contains("kong-mesh") or contains("kuma")) 
    | select(.kind != "Namespace" and .kind != "Pod")
    | select(.kind != "Secret" or .metadata.name != "kong-mesh-license") 
    | .metadata.namespace as $namespace
    | "\(.kind | ascii_downcase)/\(.metadata.name)" as $resource 
    | if $namespace
      then
        "-n \($namespace) \($resource)"
      else
        "\($resource)"
      end' \
  | xargs -d "\n" -I "{}" /bin/bash -c 'kubectl delete {} &'; \
  wait
```

## Let to find and replace new lines in GNU `sed`

### Prerequisites

MacOS comes with the BSD verion of `sed`, so to use it, you have to install GNU `sed` first

```sh
brew install gnu-sed
```

After installing it, it will be available as a `gsed` command, but if you want you can put it in the `$PATH` variable to point `sed` binary to just installed GNU `sed` version (remember to put it at the beginning of the `$PATH`):

bash

```bash
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
```

fish

```fish
set -gx PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
```

### Command

```sh
# -E | extended regexp expressions
# -z | separate lines by NUL characters (this flag is the one we are
#      interested in, and it's only available in GNU sed, not BSD's 
#      version of sed)
sed -Ez 's//'
```

## `jq`

### filter array by object properties

Filter an array of objects by the `name` property containing word `foo`

**Command**

```sh
json='[{"name": "foo"},{"name": "bar"},{"name": "foobar"}]'

echo $json | jq 'map(select(.name | contains("foo")))'
```

**Result**

```json
[
  {
    "name": "foo"
  },
  {
    "name": "foobar"
  }
]
```

**Other way of achieving the same result**

```sh
# [...]
echo $json | jq '[.[] | select(.name | contains("foo"))]'
```

## `tar`

```sh
# -x, --extract        | extract the archive
# -v                   | verbose
# -z, --gunzip, --gzip | uncompress archive with gzip - this option is
#                        ignored in most tar versions when extracting
#                        archives, so can be omitted
# -f, --file           | extract the provided file
tar -xvzf name.tar.gz
```

## swap STDIN in running process with FIFO pipe

1. Get and save Process ID (PID) of a process we are interested in swapping STDIN ap

   ```sh
   export MY_PID="61234"
   ```

2. Create a FIFO pipe we will be using as STDIN

   ```sh
   mkfifo /tmp/foo
   ```

3. Save commands which GDB will be calling to a file

   ```sh
   printf 'p (int) close(0)\np (int) openat(0, "/tmp/foo", 66)\nq\n' > /tmp/gdb_commands
   ```

   This is how this file should look like:

   ```sh
   p (int) close(0)
   p (int) openat(0, "/tmp/foo", 66)
   q
   ```

4. Run above commands in GDB for our process

   ```sh
   gdb -p $MY_PID -x /tmp/gdb_commands
   ```

5. That's it - now we can send something to our pipe

   ```sh
   echo "hello" >> /tmp/foo
   ```

## Helpful links

### Linux general

* [Beginner's Guide to Installing from Source](https://moi.vonos.net/linux/beginners-installing-from-source/) - found when reading ["Linux From Scratch" prerequisites](https://www.linuxfromscratch.org/lfs/view/stable-systemd/prologue/prerequisites.html)
* [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html) - also found when reading [LFS and Standards](https://www.linuxfromscratch.org/lfs/view/stable-systemd/prologue/standards.html)
* [Understanding the /etc/shadow File](https://linuxize.com/post/etc-shadow-file/)
* [sudoers manual](https://www.sudo.ws/man/1.8.13/sudoers.man.html)
* [Explaining Soft Link And Hard Link In Linux With Examples](https://ostechnix.com/explaining-soft-link-and-hard-link-in-linux-with-examples/)
* [sysvinit documentation](https://wiki.gentoo.org/wiki/Sysvinit) I find this documentation on gentoo site as a great place to learn more about sysvinit
* [A history of modern init systems](https://blog.darknedgy.net/technology/2015/09/05/0/)
* [If you’re not using SSH certificates you’re doing SSH wrong](https://smallstep.com/blog/use-ssh-certificates/)

#### systemd

* [Demystifying systemd](https://www.youtube.com/watch?v=tY9GYsoxeLg) - Really great presentation about systemd, with a lot of helpful commands and other hints

### RedHat based Linux

* [YUM Cheat Sheet](https://access.redhat.com/sites/default/files/attachments/rh_yum_cheatsheet_1214_jcs_print-1.pdf)

### Bash

* [Bash Extended Globbing](https://www.linuxjournal.com/content/bash-extended-globbing)

* [How To Use Bash Wildcards for Globbing?](https://www.shell-tips.com/bash/wildcards-globbing/)

### `jq`

* [Processing JSON using jq](https://gist.github.com/olih/f7437fb6962fb3ee9fe95bda8d2c8fa4)

### Networking

* [`iproute2` documentation](http://www.policyrouting.org/iproute2.doc.html)
* [YT: 3.8 Hacking the Switch: Promiscuous Mode and Switch Security](https://www.youtube.com/watch?v=YVcBShtWFmo)
* [IPv4 route lookup on Linux](https://vincent.bernat.ch/en/blog/2017-ipv4-route-lookup-linux)
* [Bastion host](https://en.wikipedia.org/wiki/Bastion_host)
* [Queueing in the Linux Network Stack](https://www.coverfire.com/articles/queueing-in-the-linux-network-stack/)
* [Controlling Queue Delay](https://queue.acm.org/detail.cfm?id=2209336)

### kubernetes

* [kubectl context vs cluster](https://stackoverflow.com/questions/56299440/kubectl-context-vs-cluster)
* [Kubernetes Networking: How to Write Your Own CNI Plug-in with Bash](https://www.altoros.com/blog/kubernetes-networking-writing-your-own-simple-cni-plug-in-with-bash/)
* [Kubernetes networking: Writing a CNI plugin from scratch](https://github.com/eranyanay/cni-from-scratch)
* [Kubectl output options](https://gist.github.com/so0k/42313dbb3b547a0f51a547bb968696ba)

### containers

* [YT: Linux Container Primitives: cgroups, namespaces, and more!](https://www.youtube.com/watch?v=x1npPrzyKfs)
