This is a local setup for the rocky server.

Features:

Simplified, no gradle
Slimmed, uses tomcat-slim
Arm64-based
Readable build script
Can use cached xwiki.war while debugging

I found the docker setup to be a little tricky to customize, so I had a go at simplifying it.

Since the system is more than one container, the objective here is to make running xwiki+database in docker/swarm a ONE file deal!

That one file is a docker-compose.yml file, and as many configuration options as possible are moved up into that file. The aim being to make the rest of the Docker ECO system as stable as possible, to the extent that xwiki-contrib doesnt even need to be checked out of github.

Taking some examples from my own rocky-compose.yml file (my first server is called rocky).

image: "xwiki:10.8.1-slim"
context: https://github.com/keithy/xwiki-contrib.git#:10/tomcat

Building against a simpler version of xwiki-contrib, in this case it is my own fork keithy/xwiki-contrib. You select a proper "official" image, or build one to order.
The build can use a github context (without cloning necessary)

      args:
        DB: mysql
        XWIKI_VERSION: 10.8.1
        XWIKI_DOWNLOAD_SHA256: ed9436b5704e8cd4bc399c017f2ef7cf32e8f18f4e75a4fcc52782d933e9893c

Build-time arguments select the database xwiki version right from the compose.yml file. There is no need to change the Dockerfile or repo's to move to the next version.

    env_file:
      - /etc/xwiki_credentials.env

Run-time arguments may be provided via a specified env file, real credentials can be in a safe place

    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki

Or in the compose file
      
    environment:
     #- DB_HOST=mariaDB # use TCP/IP
      - DB_HOST=localhost # use socket
      
Database connection via sockets or TCP

Database Server fully configure in the docker-compose.yml file

  # image: "mysql:5.7"
    image: "keithy/alpine-mariadb:armhf"
    build:
      context: https://github.com/keithy/alpine-mariadb.git#:alpine-mariadb-armhf
      
Off the shelf or roll your own, in this case I'm using a publicly available mariaDB on ARM (with a minor bug fix and pull request awaiting merge)

    env_file:
      - /etc/xwiki_credentials.env

Credentials - in the same safe place
      
    command: 
      - --character-set-server=utf8 
      - --collation-server=utf8_bin
      - --explicit-defaults-for-timestamp=1

AND finally, no need for a separate mysql.cnf file meaning that the entire shabang is contained in the one file.
         
More Detail: The Single Buildfile has a number of innovations:

    Starting from the tomcat:jre-8-slim image saves 160Mb on previous images.
    Moved all the build related stuff out of the Dockerfile, leaving only the Docker related stuff. The content of the build itself can be tweaked without touching the Dockerfile
    One Dockerfile for both mysql/postgres/(others?)
    One build/xwiki-tomcat.sh script for both mysql/posgres(others?).
    Separated build-time parameters ARGs from runtime parameters ENV
    ARGS - Buildtime arguments - provided in docker-compose.yml or via –build-arg
        The choice of database
        The choice of xwiki version/checksum
        Choice of download URL
    For debugging builds - a local copy of the war file is be used in preference to downloading a whole xwiki.war on each run (e.g. ./root/build/xwiki-10.8.1.war )
    Used a generic COPY root/. / for flexibility, easily add any files to the build/container-os without redoing the dockerfile. (e.g. the war file above)
    Runs under user xwiki(888), but should support user override **-u 10000** ok. Installation is built with files user xwiki(888):root(0) The installed software is created with ug+w permissions. Thus if the user is overridden files it creates have umask 022 (docker default) and are writable. Files it didnt create are still writable because the group(0) has permission.
    	[ http://blog.dscpl.com.au/2015/12/overriding-user-docker-containers-run-as.html ]
    Runtime environment variables can be specifically overriden by command-line compose.yml file or an .env file which can be specified in the compose.yml file. (the safest option - its completely outside the container, and the git repo - preferably in a sensible place)
    	[ https://docs.docker.com/compose/environment-variables/#the-env-file ]
    Make database socket available on the host machine (option available in the compose.yml)
    Xwiki - connects to the database via a socket on the host or TCP/IP Port. Socket is less flexible but some say more performant.
    	[ https://blog.feathersjs.com/http-vs-websockets-a-performance-comparison-da2533f13a77 ] 
    	[ https://jasonbarnabe.wordpress.com/2014/10/01/mysql-connections-sockets-vs-tcp/ ]

The example compose file has some innovations:
    Can select a proper "official" image, or build one to order.
    The build can use a github context (without cloning necessary)
    	My keithy/xwiki-contrib essentially builds the standard xwiki image with:
    		one filesystem layer
    		non-root USER
    The database 
    
    
    
    
    