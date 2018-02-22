# App.Umbrella

February 2018. by klg.

Sample repo to illustrate how to deploy a Phoenix umbrella to a VPS.

In this demo, I will use the following IP as example in the shell command.

A. 192.168.0.1  Development
B. 192.168.0.2  Building machine
C. 192.168.0.3  Production server

A is a Mac running OSX High Sierra
B and C are Linux servers, Ubuntu 16.04 LTS

## Prepare development machine

The development machine is running OSX High Sierra. On the development machine. You will need to have Erlang/Elixir/Phoenix installed. For this demo, I use the following versions.

* Erlang/OTP 20 [erts-9.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

* Elixir 1.6.1-otp-20

* Postgresql 9.6.5

You can get your version with

```bash
$ erl -version
Erlang (SMP,ASYNC_THREADS,HIPE) (BEAM) emulator version 9.1

$ elixir -v 
Erlang/OTP 20 [erts-9.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

Elixir 1.6.1 (compiled with OTP 20)
```

### Install tools (if needed)

#### Postgresql (on OSX)

On a Mac the simpliest is to use brew for installation.

Reference: https://brew.sh/index_fr.html

```bash
$ brew install postgresql
$ brew services start postgresql
```

In case You need to add user postgres.

```bash
$ createuser -s postgres
```

#### Asdf

In this demo I will use asdf to install requested package.

Reference: https://github.com/asdf-vm/asdf

$ git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.2

For OSX, You need to complete the installation with

```bash
$ echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bash_profile
$ echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bash_profile
$ source ~/.bash_profile
```

I found an issue, but that might be solved now. In case...

https://stackoverflow.com/questions/32418438/how-can-i-disable-bash-sessions-in-os-x-el-capitan 

If You need to, type this command

```bash
$ touch ~/.bash_sessions_disable
```

Now add plugins for both Erlang and Elixir.

```bash
$ asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
$ asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir 
```

#### Erlang

Asdf is now installed, You will need to add Erlang. At the time of writing, the latest is 20.1

```bash
$ asdf install erlang 20.1
$ asdf global erlang 20.1
```

#### Elixir

Reference: https://github.com/asdf-vm/asdf-elixir

On the documentation page of the elixir plugin. You can read

"If you would like to use precompiled binaries built with a more recent OTP, you can append -otp-${OTP_VERSION} to any installable version that can be given to asdf-elixir."

```bash
$ asdf install elixir 1.6.1-otp-20
$ asdf global elixir 1.6.1-otp-20
```

#### Phoenix

In case You don't have it yet.

```bash
$ mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez
```

## Create umbrella application

Now that all tools are installed, it's time to start a new project. In this demo, the name of the project is app. 

```bash
$ mix phx.new app --umbrella --no-brunch
$ cd app_umbrella/
```

As I have the tree tool installed I can have a look at the project structure.

```bash
$ tree -I 'test*|deps|_build'
.
├── README.md
├── apps
│   ├── app
│   │   ├── README.md
│   │   ├── config
│   │   │   ├── config.exs
│   │   │   ├── dev.exs
│   │   │   ├── prod.exs
│   │   │   └── prod.secret.exs
│   │   ├── lib
│   │   │   ├── app
│   │   │   │   ├── application.ex
│   │   │   │   └── repo.ex
│   │   │   └── app.ex
│   │   ├── mix.exs
│   │   └── priv
│   │       └── repo
│   │           ├── migrations
│   │           └── seeds.exs
│   └── app_web
│       ├── README.md
│       ├── config
│       │   ├── config.exs
│       │   ├── dev.exs
│       │   ├── prod.exs
│       │   └── prod.secret.exs
│       ├── lib
│       │   ├── app_web
│       │   │   ├── application.ex
│       │   │   ├── channels
│       │   │   │   └── user_socket.ex
│       │   │   ├── controllers
│       │   │   │   └── page_controller.ex
│       │   │   ├── endpoint.ex
│       │   │   ├── gettext.ex
│       │   │   ├── router.ex
│       │   │   ├── templates
│       │   │   │   ├── layout
│       │   │   │   │   └── app.html.eex
│       │   │   │   └── page
│       │   │   │       └── index.html.eex
│       │   │   └── views
│       │   │       ├── error_helpers.ex
│       │   │       ├── error_view.ex
│       │   │       ├── layout_view.ex
│       │   │       └── page_view.ex
│       │   └── app_web.ex
│       ├── mix.exs
│       └── priv
│           ├── gettext
│           │   ├── en
│           │   │   └── LC_MESSAGES
│           │   │       └── errors.po
│           │   └── errors.pot
│           └── static
│               ├── css
│               │   └── app.css
│               ├── favicon.ico
│               ├── images
│               │   └── phoenix.png
│               ├── js
│               │   ├── app.js
│               │   └── phoenix.js
│               └── robots.txt
├── config
│   ├── config.exs
│   ├── dev.exs
│   └── prod.exs
├── mix.exs
└── mix.lock
```

/apps/app holds the database backend.
/apps/app_web holds the web interface.

### Create git repo

Optional, but highly recommended.

```bash
$ git init
$ git add .
$ git commit -m "Initial commit"
```

### Create the production database

From the database part of your project...

```bash
$ cd apps/app
$ MIX_ENV=prod mix ecto.create
$ MIX_ENV=prod mix ecto.migrate
```

In case You have a seed file.

```bash
$ MIX_ENV=prod mix run priv/repo/seeds.exs
```

It's helpful to create a dump of the production table, this dump will be used later on the production server to create initial database. Keep this file for the moment in your home folder.

```bash
$ sudo -u postgres pg_dump next_prod > ~/next_prod.dump
```

You can copy this file on B and C.

```bash
$ scp ~/next_prod.dump 192.168.0.1:~/
$ scp ~/next_prod.dump 192.168.0.2:~/
```


### Add distillery to the root mix.exs

Reference: https://github.com/bitwalker/distillery

Quite easy to follow documentation. 

Start by updating the root mix file and add distillery. Please be careful with the mix.exs files, because there are 3 in this example.

```bash
$ vim mix.exs

{:distillery, "~> 1.5", runtime: false}

$ mix deps.get
```

#### Configure distillery

Update the production config file from the web part.

Note the use of system port... Later You will pass this port when starting the server.

```bash
$ vim apps/app_web/config/prod.exs
config :app_web, AppWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  #url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  #  
  server: true,
  root: ".",
  version: Application.spec(:deploy_phoenix, :vsn)
```

Please note it is mandatory to set a correct host for websocket to work. Replace localhost by your domain name!

To initialize the release, type the following command.

```bash
$ mix release.init
```

This will create a rel folder at the root of the project.

Time to save to git.

```bash
$ git add .
$ git commit -m "Add README"
```

## Prepare the building machine

In this example. I use a intermediate server to build the release. The idea is to keeè the production server as untouched as possible. It only needs a database backend, and the release binaries. This can also be done directly on the production server. 

It should be setup close as the production server.

The server is a Linux Ubuntu 16.04 LTS. It uses apt has packet manager.

You access the machine with ssh. The user on the development machine should have a corresponding account on the building server.

```bash
$ ssh 192.168.0.2
```

or if user does not match, specify at it the command line.

```bash
$ ssh user@192.168.0.2
```

To prepare the server, You can start by updating the system.

```bash
$ sudo apt-get update
$ sudo apt-get upgrade
```

Add a source folder, it will be used later for storing sources.

```bash
$ mkdir ~/elixir_src
```


### Install packages

Install the following packages with the following command

$ sudo apt-get install <package_name>

Replace by this list...

* build-essential 
* autoconf 
* m4 
* libncurses5-dev 
* libwxgtk3.0-dev 
* libgl1-mesa-dev 
* libglu1-mesa-dev 
* libpng3 
* libssl-dev
* postgresql 
* postgresql-contrib 

libwxgtk3.0-dev was needed to run observer with Erlang 19. I did not yet run observer with a 20.1 release. It might is optional if You don't want observer to run.

You will need also nodejs and yarn. Here is the method used.

```bash
$ sudo add-apt-repository ppa:certbot/certbot
$ sudo apt-get update
python-certbot-apache 
software-properties-common

$ curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
$ echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
$ sudo apt-get update
```

Now install with apt...

* yarn
* nodejs

The full command is 

```bash
$ sudo apt-get install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libpng3 libssl-dev postgresql postgresql-contrib yarn nodejs
```

### Post configure postgresql

The simpliest is to add a postgres user w/ password postgres. But feel free to add another account. Just consider You will need db user info to configure your application Repo.

```bash
$ sudo apt-get install postgresql postgresql-contrib
$ sudo -u postgres psql
postgres=# ALTER USER postgres PASSWORD 'postgres';
ALTER ROLE
postgres=# \q
```


### Build the release

You will need to copy your project from machine A to B.

From the machine A, step down one folder, to go to the parent directory of the umbrella project.

```bash
$ cd ../
$ scp -r app_umbrella/ 192.168.0.2:~/elixir_src/
```

Now connect to the building machine.

```bash
$ ssh 192.168.0.2
```

Go into the root folder of the project, clean previous build and deps.

```bash
$ cd elixir_src/app_umbrella
$ rm -rf _build deps
$ mix deps.get
```

Build database and digest assets.

```bash
$ cd apps/app
$ MIX_ENV=prod mix ecto.create
$ MIX_ENV=prod mix ecto.migrate

$ cd ../app_web
$ MIX_ENV=prod mix phx.digest
```

You can restore the data from the dump file.

```bash
$ sudo -u postgres psql app_prod < ~/app_prod.dump 
```

Build release

```bash
$ cd ../../
$ MIX_ENV=prod mix release
```

After the build is complete, You will find the production archive. This tar file needs to be copied in the production server.

```bash
$ cd _build/prod/rel/app_umbrella/releases/0.1.0/
$ scp app_umbrella.tar.gz 192.168.0.2:~/
```


## Production server

The final steps are on the production machine. It's also a Linux server, running Ubuntu 16.04 LTS. 
No need for Erlang nor Elixir nor Phoenix! You just add the tarball.

Please install postgres as for the building machine.

We will put Nginx in front of the application, as a webproxy. To start the application We will need to configure systemd. The hardest part on the production server is to install additional services.

You should have the archive, and the dump file in your home directory.

Connect and extract the archive

```bash
$ ssh 192.168.0.2
$ mkdir -p elixir/app_umbrella
$ cd elixir/app_umbrella
$ tar -xzvf ~/app_umbrella.tar.gz
```

In case You want to use another account.

```bash
$ sudo -u postgres psql
postgres=# CREATE DATABASE app_prod;
postgres=# CREATE USER appuser WITH PASSWORD 'mypassword';
postgres=# GRANT ALL PRIVILEGES ON DATABASE app_prod TO appuser;
postgres=# \q
```

Do you remeber the dump file? You can use it to reload schema.

$ sudo -u postgres psql next_prod < ~/next_prod.dump 

### Systemd

Reference: https://doc.ubuntu-fr.org/systemd 
Reference: https://mfeckie.github.io/Phoenix-In-Production-With-Systemd/ 

Systemd is now the way to go w/ Ubuntu. It replaces start scripts.

The idea is to create a service script for the application, and use it to start the server. It will accept a port variable to start the service. Remember this system port?

You need to be root to do this, and You need to use the name of your user account. In this demo, I will just use username.

```bash
$ sudo vim /lib/systemd/system/app_umbrella.service
[Unit]
Description=App Umbrella server app
After=network.target

[Service]
User=username
Group=username
Restart=on-failure

Environment=HOME=/home/username/elixir/app_umbrella

ExecStart=/home/username/elixir/app_umbrella/bin/app_umbrella foreground
ExecStop=/home/username/elixir/app_umbrella/bin/app_umbrella stop

[Install]
WantedBy=multi-user.target
```

We want to specify the application port.

```bash
$ sudo systemctl edit app_umbrella.service
[Service]
Environment="PORT=4000"
```

This should open nano editor, hit ctrl-x to save and exit.

This will create the folder /etc/systemd/system/app_umbrella.service.d
with the file override.conf

If everything is fine, continue with...

```bash
$ sudo systemctl enable app_umbrella.service 
$ sudo systemctl daemon-reload
$ sudo systemctl status app_umbrella.service 
```

... and You should see your service running on port 4000.



### Nginx

The last part is to configure Nginx.

```bash
$ sudo apt-get install nginx
$ cd /etc/nginx
```

Reference: https://korben.info/configurer-nginx-reverse-proxy.html 

Here is a simple config file to add to conf.d/proxy.conf

```bash
$ sudo vim conf.d/proxy.conf
proxy_redirect          off;
proxy_set_header        Host            $host;
proxy_set_header        X-Real-IP       $remote_addr;
proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header        Upgrade       $http_upgrade;
proxy_set_header        Connection       "upgrade";
client_max_body_size    10m;
client_body_buffer_size 128k;
client_header_buffer_size 64k;
proxy_connect_timeout   90;
proxy_send_timeout      90;
proxy_read_timeout      90;
proxy_buffer_size   16k;
proxy_buffers       32   16k;
proxy_busy_buffers_size 64k;
```

Now create a config file for the application. This will be short, because proxy conf is already setup by the other file. And link the file in the site-enabled folder.

```bash
$ cd sites-available
$ sudo cp default app_umbrella
$ sudo vim app_umbrella
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	index index.html index.htm index.nginx-debian.html;

	server_name _;
	location / {
	proxy_pass http://127.0.0.1:4000;
	}
}
$ cd ../sites-enabled
$ sudo ln -s ../sites-available/app_umbrella ./
```

If everything went well, your server should be running now.

