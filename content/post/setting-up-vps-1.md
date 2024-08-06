+++
title = 'Setting up your VPS'
date = 2024-08-06T10:54:58+01:00
draft = false
tags = ['setup', 'server', 'vps', 'aws', 'lightsail', 'ssh', 'firewall', 'unattended-upgrades', 'ssh-keys', 'linux']
+++

# Initial setup of a VPS

In this guide, I'll be showing you how to get started with a brand new Debian 12 instance running in an AWS Lightsail container.

We will be:

- Setting up a new user
- Adding SSH keys
- Establishing a firewall
- Unattended, automating updates
- Improving security

## Getting started

Depending on your VPS provider, you may have to setup root user password with:
`passwd`

First things first, updates:

```sh
sudo apt update
sudo apt upgrade
# some basic utilities I normally require from the start
sudo apt install wget curl net-tools vim rsync git

# sudo dpkg-reconfigure tzdata ## to setup timezone if in another region
```

Setup a new user so that we don't have to run as root.

```sh
sudo adduser benkalmus
# enter a new password

# this will give you ability to run sudo commands without being root
usermod -aG sudo benkalmus
## will need to reboot! (sudo reboot)

# alternatively, manual:
sudo visudo
# then insert permissions to bottom of file
benkalmus ALL=(ALL:ALL) ALL
```

From now on, you want to login as your new user and complete the rest of the guide as this user.

login:

```sh
su - benkalmus
```

## Configuring SSH

This is important as we will be removing password logins, this ensures that only authorised machines can login. However, keep in mind that you no longer be able to access your machine from anywhere without SSH keys.
Usually you will already have generated existing SSH keys, for example your AWS instance will have a default ssh pair.
We will generate a new pair ourselves with:

```shell
ssh-keygen -t ed25519 -C "contact@benkalmus.com"
# select your home directory for file location
# you do not need to enter a passphrase
```

copy over ssh keys to VPS.

```sh
VPS_IP_ADDRESS="1.2.3.4" # change this to your VPS's IPv4
ssh-copy-id username@$VPS_IP_ADDRESS
```

Validate your ssh key pair will work by attempting to ssh to your machine using the identity key file explictly:

```sh
ssh -v -i ~/.ssh/id_ed25519 benkalmus@$VPS_IP_ADDRESS
```

If the above worked and you didn't get a password prompt, you are doing great.

This would be a good time to git clone bash aliases, assuming you have another ssh key pair for your github/gitlab account.

Now on my machine, we can save this config so that we can connect to the server without remembering its ip address:

```sh
nvim ~/.ssh/config

Host my-new-vps
    HostName 1.2.3.4
    User benkalmus
    Port 22
    # uncomment the following if you wish to use a specific key pair
    #IdentityFile ~/.ssh/id_ed25519

# finally, confirm the changes worked
ssh my-new-vps
```

### Disable password auth

Now we're ready to lock the server in by disabling password authentication.
Disable root login and password-based authentication:

```sh
sudo vim /etc/ssh/sshd_config

#Set the following options:

PermitRootLogin no
PasswordAuthentication no
```

```sh
sudo systemctl restart sshd
```

## Set up a firewall (optional but recommended)

```sh
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
```

I highly recommend you discover how to add additional rules to your new setup firewall.
**NOTE**: If you will be hosting a some service that requires networking, don't forget to add a new rule for tcp/udp port.

## Automatic updates

```sh
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades

#Info: the following config is changed:
/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";

# also worth configuring unattended upgrades with reboots and email alerts:
/etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Automatic-Reboot
Unattended-Upgrade::Automatic-Reboot-Time

Unattended-Upgrade::Mail "contact@benkalmus.com";
Unattended-Upgrade::MailReport "only-on-error";

## if you decide to use email, you must install:
sudo apt install mailutils
# perform a test
sudo unattended-upgrade -d
```

You are now ready to go!

## Recommended options

```sh
# for hosting static sites:
sudo apt install nginx
```

Concerned about malicious users attempting to connect? Perhaps you prefer to leave password auth enabled?
In that case, fail2ban is your friend. It will ban IP addresses failing to connect too many times.
It's highly configurable and beyond the scope of this post.

```sh
sudo apt install fail2ban
```

Mosh, a more reliable method to make remote shell connection on poor networks. Communication is over UDP, on port 60000-61000. I recommend trying it out.

```sh
sudo apt install mosh

sudo ufw allow 60000:61000/udp
```

Once installed on both host and server machines: test it as you would with ssh:

```sh
msh $VPS_IP_ADDRESS
# or
msh my-new-vps
```

## Additional Resources

For an in depth guide to hardening your server, I highly recommend reading [Ivan's post](https://ivansalloum.com/comprehensive-linux-server-hardening-guide).
