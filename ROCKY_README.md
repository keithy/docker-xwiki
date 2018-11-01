#### Simplify
I found the docker setup to be a little tricky to customize, so I had a go at simplifying it.

Since the system is more than one container, the objective here is to make running xwiki+database in docker/swarm a ONE file deal!

That one file is a docker-compose.yml file, and as many configuration options as possible are moved up into that file. The aim being to make the rest of the Docker ECO system as stable as possible, to the extent that from a users perspective xwiki-contrib doesnt even need to be checked out of github.

*Usage:* (Download the docker-compose.yml file, and docker-compose up)
'''
curl https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/docker-compose-mysql.yml -o docker-compose.yml
docker-compose up
'''

#### Features:

- Simplified, no gradle
- Slim-med, uses tomcat-slim (saves ~160Mb)
- Arm64 support
- SOLID principle - one responsibility per...
  - Docker configuration = DockerFile
  - Xwiki installation = build/xwiki-tomcat.sh
- Readable build script
- Option to use cached xwiki.war while debugging
- Select docker-compose.yml as the base system of choice mysql/postgres (can symlink)
- Write docker-compose.override.yml for server specific configuration details.

Taking some examples from rocky-server.override.yml file (my first server is called rocky).
```
  wiki:
    # once built the image has this name
    image: "xwiki:10.9-slim"
    build: 
      # remote definition
      context: "https://github.com/keithy/docker-xwiki.git#keithy:latest"
or
      # local definition
      context: "10.9-tomcat"
```

Building against a simpler version of xwiki-contrib, in this case it is my own fork keithy/xwiki-contrib. You select a proper "official" image, or build one to order. The build can use a github context (cloning not necessary)
```
      args:
        DB: mysql
        XWIKI_VERSION: 10.8.1
        XWIKI_DOWNLOAD_SHA256: ed9436b5704e8cd4bc399c017f2ef7cf32e8f18f4e75a4fcc52782d933e9893c
```
Build-time arguments select the database xwiki version right from the compose.yml file. There is no need to change the Dockerfile or repo's to move to select the version.
```
    env_file:
      - /etc/xwiki_credentials.env
```
Run-time arguments: Defaults are defined in the DockerFIle, this allows the ovverride to provide alternative
credentials via an env_file.
```
    ports:
      - "8080:8080" 
```
Unfortunately ports cannot be overriden (without major silliness)
```      
    environment:
     #- DB_HOST=mariaDB # use TCP/IP
      - DB_HOST=localhost # use socket
```      
Database connection via sockets or TCP 
(not supported with current libmysql-java, the maria equivalent does support socket connections)

Database Server fully configured in the docker-compose.yml file
```
  mariaDB:
    # image: "mysql:5.7" 
    image: "yobasystems/alpine-mariadb" #includes arm support
```      
Off the shelf or roll your own - use a publicly available mariaDB on ARM/Intel
```
    volumes:
      - db:/var/lib/mysql
      - /run/mysqld:/run/mysqld # make the socket available on the host
```
Make the socket available for local tools
```
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
```
Initial database creation parameters, these can be overriden in an override.yml file but 
regrettably they cannot be overridden by an env_file: of credentials (as in wiki: above).
Once the database is created, access passwords can be changed, and hibernate.cfg.xml 
updated to match.
```      
    command: 
      - --character-set-server=utf8 
      - --collation-server=utf8_bin
      - --explicit-defaults-for-timestamp=1
```
Adding the above options means that there is no need for a separate mysql.cnf file.
Thus satisfying the ONE-FILE requirement.

#### The Database Client - coolness
```
  client:
    # image: "mysql:5.7" 
    image: yobasystems/alpine-mariadb:armhf
    container_name: mysql_CLI
    networks:
      - bridge
    volumes:
      - /run/mysqld:/run/mysqld # access the socket on the host
    depends_on:
      - mariaDB
    entrypoint:
      - mysql 
      - --user=root     
      - --password=xwiki # this can be replaced with a root password in .my.cnf
      - --host=mariaDB
      - --protocol=TCP
      - --default-character-set=utf8
      - --init-command=GRANT ALL ON *.* TO `xwiki`@`%`
```
This client sets up the necessary database permissions on it's first launch, then finishes.
This client may be used interactively if needed.
   
#### More Detail: The Single Buildfile has a number of innovations:

- Starting from the tomcat:jre-8-slim image saves 160Mb on previous images.
- Arm64 support
- SOLID principle - one responsibility per...
  - Docker configuration = DockerFile
  - Xwiki installation = build/xwiki-tomcat.sh
- One Dockerfile for both mysql/postgres/(others?)
- One build/xwiki-tomcat.sh script for both mysql/posgres(others?).
- Separated build-time parameters ARGs from runtime parameters ENV
- ARGS - Buildtime arguments - provided in docker-compose.yml or via –build-arg
	- The choice of database
    - The choice of xwiki version/checksum
    - Choice of download URL
- For debugging builds - a local copy of the war file is be used in preference to downloading a whole xwiki.war on each run (e.g. ./root/build/xwiki-10.8.1.war ) NOTE: this file does bloat the final image.
- Used a generic COPY root/. / for flexibility, easily add any files to the build/container-os without redoing the dockerfile. (e.g. the war file above)
- Runs under user xwiki(888), but should support user override **-u 10000** ok. Installation is built with files user xwiki(888):root(0) The installed software is created with ug+w permissions. Thus if the user is overridden files it creates have umask 022 (docker default) and are writable. Files it didnt create are still writable because the group(0) has permission.
	- [ http://blog.dscpl.com.au/2015/12/overriding-user-docker-containers-run-as.html ]
- Runtime environment variables can be specifically overriden by command-line, *override..yml, or env_file (the safest option)
	- [ https://docs.docker.com/compose/environment-variables/#the-env-file ]
- Make database socket available on the host machine.
- Xwiki - (in the future) may connect to the database via a socket on the host or TCP/IP Port. Socket is less flexible but some say more performant.
	- [ https://blog.feathersjs.com/http-vs-websockets-a-performance-comparison-da2533f13a77 ] 
    - [ https://jasonbarnabe.wordpress.com/2014/10/01/mysql-connections-sockets-vs-tcp/ ]

    
    
    
    
    