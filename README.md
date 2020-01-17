[![Build Status](https://jenkins.testbed.tier.internet2.edu/buildStatus/icon?job=docker/grouper/2.4.0-a29-u14-w3-p2-20190217)](https://jenkins.testbed.tier.internet2.edu/buildStatus/icon?job=docker/grouper/2.4.0-a29-u14-w3-p2-20190217)



# Upgrading from 2.3 to 2.4

If upgrading from Grouper version 2.3 to 2.4 and using LDAP, modifications will be needed in subject.properties and grouper-loaders.proprties. Further details about this can be found at the following URL:
https://spaces.at.internet2.edu/display/Grouper/vt-ldap+to+ldaptive+migration+for+LDAP+access

In particular, in subject.properties, *.param.base.value should be adjusted to only contain the RDN (Relative Distinguished Name), not the full DN.  For example, "OU=People", not "OU=People,DC=domain,DC=edu"

Additional upgrade information can be found at the following URL: https://spaces.at.internet2.edu/display/Grouper/v2.4+Upgrade+Instructions+from+v2.3

# Supported tags

-	latest
-   patch specific tags* (i.e. 2.3.0-a97-u41-w11-p16)

\* Patch builds are routinely produced, but not necessarily for each patch release. The following monikers are used to construct the tag name:
 
- a = api patch number
- u = ui patch number
- w = ws patch number
- p = pspng patch number

# Quick reference

-	**Where to get help**:  
        [tier-packaging@internet2.edu](mailto:tier-packaging@internet2.edu?subject=Grouper%20Image%20Help)

-	**Where to file issues**:  
	[https://github.internet2.edu/docker/grouper/issues](https://github.internet2.edu/docker/grouper/issues)

-	**Maintained by**:  
	[TIER Packaging Working Group](https://spaces.internet2.edu/display/TPWG)

-	**Supported Docker versions**:  
	[the latest release](https://github.com/docker/docker-ce/releases/latest) (down to 1.6 on a best-effort basis)

# What is Grouper?

Grouper is an enterprise access management system designed for the highly distributed management environment and heterogeneous information technology environment common to universities. Operating a central access management system that supports both central and distributed IT reduces risk.

> [www.internet2.edu/products-services/trust-identity/grouper/](https://www.internet2.edu/products-services/trust-identity/grouper/)

![logo](https://www.internet2.edu/media/medialibrary/2013/10/15/image_grouper_logowordmark_bw.png)

# How to use this image

This image provides support for each of the Grouper components/roles: Grouper Daemon/Loader, Grouper UI, Grouper Web Services, and Grouper SCIM Server.

## Starting each role

While TIER recommends/supports using Docker Swarm for orchestrating the Grouper environment, these containers can be run directly (or with other orchestration products). Both examples are shown below. It should be noted that these examples will not run independently, but required additional configuration to be provided before each container will start as expected.

### Daemon/Loader

Run the Grouper Daemon/Loader as a service. If the daemon/loader container dies unexpectedly, it may be due to memory contraints. Refer to the "Grouper Shell/Loader" section below for information on how to tweak memory settings.   

```console
$ docker service create --detach --name grouper-daemon tier/grouper:latest daemon
```

Run the Grouper Daemon/Loader as a standalone container.

```console
$ docker run --detach --name grouper-daemon tier/grouper:latest daemon
```

### SCIM Server

Runs the Grouper SCIM Server as a service.

```console
$ docker service create --detach --publish 9443:443 --name grouper-ws tier/grouper:latest scim
```

Runs the Grouper Web Services in a standalone container. 

```console
$ docker run --detach --publish 9443:443 --name grouper-daemon tier/grouper:latest scim
```

### UI

Runs the Grouper UI as a service.

```console
$ docker service create --detach --publish 443:443 --name grouper-ui tier/grouper:latest ui
```

Runs the Grouper UI in a standalone container.

```console
$ docker run --detach --name --publish 443:443 grouper-ui tier/grouper:latest ui
```

### Web Services

Runs the Grouper Web Services as a service. 

```console
$ docker service create --detach --publish 8443:443 --name grouper-ws tier/grouper:latest ws
```

Runs the Grouper Web Services in a standalone container. 

```console
$ docker run --detach --publish 8443:443 --name grouper-daemon tier/grouper:latest ws
```

### UI and Web Services

> This method is good when first starting to work with Grouper, but when scaling Grouper UI or Web Services it is advisable to use the individual roles noted above.

Runs the Grouper UI and Web Services as a combined service. (You should really run these as individual roles to take advantage of Docker service replicas.) 

```console
$ docker service create --detach --publish 443:443 --name grouper-web tier/grouper:latest ui-ws
```

Runs the Grouper UI and Web Services in a combined container. This good when first starting to work with Grouper, but when scaling Grouper UI or Web Services it is advisable to use the individual roles noted above.

```console
$ docker run --detach --publish 443:443 --name grouper-web tier/grouper:latest ui-ws
```

### GSH

Runs the Grouper Shell in a throwaway container. This makes it easy to run Grouper commands and Grouper Shell scripts. Since it is interactive it does not run as a service.

```console
$ docker run -it --rm tier/grouper:latest bin/gsh <optional GSH args>
```

# Configuration

## Grouper Configurations

There are several things that are required for this image to successfully start. At a minimum, the `grouper.hibernate.properties` and `subject.properties` (or the old `sources.xml` equivalent) files need to be customized and available to the container at start-up. 

Grouper config files maybe placed into `/opt/grouper/conf` and these files will be put into the appropriate location based on the role the container assumes. Docker Secrets starting with the name `grouper_` should take precedence over these files. (See below.)

## Web Apps Configuration

If starting the container to serve the Grouper UI, Grouper Web Services, Grouper SCIM Server components, a TLS key and cert(s) need to be applied to those containers. 

The Grouper UI also requires some basic Shibboleth SP configuration. The `/etc/shibboleth/shibboleth2.xml` file should be modified to set:
- an entityId for the SP
- load IdP or federation metadata 
- set the SP's encryption keys
- the identity attribute of the subject to be passed to Grouper

If encryption keys are defined in the `shibboleth2.xml` file, then the key/cert files should be provided as well. The `attribute-map.xml` file has most of the common identity attributes pre-configured, but it (and other Shibboleth SP files) can be overlaid/replaced as necessary.

(See the section below.)

## General Configuration Mechanism

There are three primary ways to provide Grouper and additional configuration files to the container: Docker Config/Secrets, customized images, and bind mounts. Depending upon your needs you may use a combination of two or three of these options.

### Secrets/Configs

Docker Config and Docker Secrets are Docker's way of providing configurations files to a container at runtime. The primary difference between the Config and Secrets functionality is that Secrets is designed to protect resources/files that are sensitive.

For passing full files into the container, this container will make any secrets with secret names prepended with `grouper_` available to the appropriate Grouper component's conf directory (i.e. `<GROUPER_HOME>/conf` or `WEB-INF/classes`). Any secrets with secret names starting with `shib_` will be available in the Shibboleth SP `/etc/shibboleth/` directory. Any secrets with secret names starting with `httpd_` will be available to `/etc/httpd/conf.d` directory. Finally, if a secret with the name of `host-key.pem` will be mapped to the httpd TLS cert used by Grouper UI, Grouper WS, and Grouper SCIM Server containers. These files will supercede any found in the underlying image.

Docker Secrets can also be used to pass in strings, such as a database connection string password, into the component config. To pass in the Grouper database connection string, one might set the property and value as such:

```text
hibernate.connection.password.elConfig = ${java.lang.System.getenv().get('GROUPER_DATABASE_PASSWORD_FILE') != null ? org.apache.commons.io.FileUtils.readFileToString(new("java.io.File", java.lang.System.getenv().get('GROUPER_DATABASE_PASSWORD_FILE')), "utf-8") : java.lang.System.getenv().get('GROUPER_DATABASE_PASSWORD') }
```

Note that the default property name has been changed by appending `.elConfig`. (This causes Grouper to evaluate the string before saving the value.) The expression allows deployers to use a file containing only the database password as a Docker Secret and reference the file name via the `GROUPER_DATABASE_PASSWORD_FILE` environment property. This allows the config files to be baked into the image, if desired. Also, but not recommended, the database password could just be set in the Docker Service definition as an environment variable, `GROUPER_DATABASE_PASSWORD`. (Technically the expression can be broken up and just the desired functionality used.) Of course, using Grouper's MorphString functionality is supported and likely is the best option, but does require more effort in setting it up.

Secrets can be managed using the `docker secret` command: `docker secret create grouper_grouper.hibernate.properties ./grouper.hibernate.properties`. This will securely store the file in the swarm. Secrets can then be assigned to the service `docker service create -d --name daemon --secret grouper_grouper.hibernate.properties --secret grouper_sources.xml tier/grouper daemon`.

> `docker run` does not support secrets; Bind mounts need to be used instead, which is technically what Docker Compose does when not running against a Swarm.

### Bind Mounts

Bind mounts can be used to connect files/folders on the Docker host into the container's file system. Unless running in swarm mode, Docker Secrets are not supported, so we can use a bind mount to provide the container with the configuration files.

```console
$ docker run --detach --name daemon \
  --mount type=bind,src=$(pwd)/grouper.hibernate.properties,dst=/run/secrets/grouper_grouper.hibernate.properties \
  --mount type=bind,src=$(pwd)/sources.xml,dst=/run/secrets/grouper_sources.xml \
  tier/grouper daemon
```

### Customized Images

Deployers will undoubtedly want to add in their files to the container. Things like additional jar files defining Grouper Hooks, or things like images and css files. This can be accomplished by building custom images. **Deployers should NOT use this method to store sensitive configuration files.**

To add a favicon to the Grouper UI, we use the tier/grouper images as a base and `COPY` our local `favicon.ico` into the image. While we are at it, we define this image as a UI image by specifying the default commnd (i.e `CMD`) of `ui`.

```Dockerfile
FROM tier/grouper:latest

COPY favicon.ico /opt/grouper/grouper.ui/

CMD ui
```

To build our image:

```console
$ docker build --tag=org/grouper-ui .
```

This image can now be used locally or pushed to an organization's Docker repository.


## Environment Variables

Deployers can set runtime variables to both the Grouper Shell and Loader/Daemon and to Tomcat/Tomcat EE using environment variables. These can be set using the `docker run` and `docker service creates`'s `--env` paramater.

### Grouper Shell/Loader

The following environment variables are used by the Grouper Shell/Loader: 
- MEM_START: corresponds to the java's `-Xms`. (default is 64m)
- MEM_MAX: corresponds to java's `-Xmx`. (default is 750m)

### Tomcat/TomEE

Amongst others variables defined in the `catalina.sh`, the following variables would like be useful for deployers:
- CATALINA_OPTS: Java runtime options to only be used by Tomcat itself.

# File System Endpoints

Here is a list of significant directories and files that deployers should be aware of:

- `/opt/grouper/conf/`: a common directory to place non-sensitive config files that will be placed into the appropriate location for each Grouper component at container start-up.
- `/opt/grouper/lib/`: a common directory to place additional jar files that will be placed into the appropriate location for each Grouper component at container start-up.
- `/opt/grouper/grouper.apiBinary/`: location to overlay Grouper GSH or Daemon/Loader files.
`/opt/grouper/grouper.scim/`: location for overlaying Grouper SCIM Server web application files (expanded `grouper-ws-scim.war`).
- `/opt/grouper/grouper.ui/`: location for overlaying Grouper UI web application files (expanded `grouper.war`).
- `/opt/grouper/grouper.ws/`: location for overlaying Grouper Web Services web application files (expanded `grouper-ws.war`).
- `/etc/httpd/conf.d/ssl-enabled.conf`: Can be overlaid to change the TLS settings when running Grouper UI or Web Servicse.
- `/etc/shibboleth/`: location to overlay the Shibboleth SP configuration files used by the image.
- `/opt/tomcat/`: used to run Grouper UI and Grouper WS
- `/opt/tomee/`: used to run the Grouper SCIM Server.
- `/var/run/secrets`: location where Docker Secrets are mounted into the container. Secrets starting with `grouper_`, `shib_`, and `httpd_` have special meaning. See `Secrets/Configs` above.
- `/usr/lib/jvm/zulu-8/jre/lib/security/cacerts`: location of the Java trust store.

To examine baseline image files, one might run `docker run --name=temp -it tier/grouper bash` and browse through these file system endpoints. While the container is running one may copy files out of the image/container using something like `docker cp containerId:/opt/grouper/grouper.api/conf/grouper.properties .`, which will copy the `grouper.properties` to the Docker client's present working directory. These files can then be edited and applied via the mechanisms outlined above.

# Web Application Endpoints

Here is a list of significant web endpoints that deployers should be aware of:

- `/grouper/`: location of the Grouper UI application
- `grouper-ws/`: location of the Grouper WS application.
- `/grouper-ws-scim/`: location of the Grouper SCIM Server application.

The endpoint that is available is dependent upon the role of the container.

# Provisioning a Grouper Database

Using standard methods, create a MariaDb Server and an empty Grouper database. Create a database user with privileges to create and populate schema objects. Set the appropriate database connection properties in `grouper.hibernate.properties`. Be sure to the user created with schema manipulation privileges as the db user.

Next populate the database by using the following command.

```console
$ docker run -it --rm \
  --mount type=bind,src=$(pwd)/grouper.hibernate.properties,dst=/run/secrets/grouper_grouper.hibernate.properties \
  tier/grouper gsh -registry -check -runscript -noprompt
```

Note: a less privileged database user maybe used when running the typical Grouper roles. This user needs SELECT, INSERT, UPDATE, and DELETE privileges on the schema objects.

# Provisioning a Grouper Database

Using standard methods, create a MariaDb Server and an empty Grouper database. Create a database user with privileges to create and populate schema objects. Set the appropriate database connection properties in `grouper.hibernate.properties`. Be sure that the user is created with schema manipulation privileges.

Next populate the database by using the following command.

```console
$ docker container run -it --rm \
  --mount type=bind,src=$(pwd)/grouper.hibernate.properties,dst=/run/secrets/grouper_grouper.hibernate.properties \
  tier/grouper gsh -registry -check -runscript -noprompt
```

Also, it is possible to just connect directly to the container, create the DDL, and copy it out. This is necessary if your DBAs would prefer to manually execute the DDL to create the schema objects:

```console
$ docker container run -it --name grouper \
  --mount type=bind,src=$(pwd)/grouper.hibernate.properties,dst=/run/secrets/grouper_grouper.hibernate.properties \
  tier/grouper

  gsh -registry -check

  exit

$ docker container cp grouper:/opt/grouper/grouper.apiBinary/ddlScripts/ .
$ docker container rm -f grouper
``` 
The generated DDL will be on the host in the `ddlScripts` directory.

Note: A less privileged database user maybe used when running the typical Grouper roles. This user just needs SELECT, INSERT, UPDATE, and DELETE privileges on the tables and views. Running in this configuration requires DBAs to manually run the DDL scripts.

# Configuring the embedded Shibboleth SP 

The Shibboleth SP needs to be configured to integrate with one or more SAML IdPs. Reference the Shibboleth SP documentation for specific instructions, but here is information on generating an encryption key/cert pair and mounting them (all of which are environment specific) and the shibboleth2.xml into the container.

1. Start a temporary container and generate the key/cert pair:
    ```
    $ docker container run -it --name grouper \
      tier/grouper bash

    cd /etc/shibboleth
    ./keygen.sh -f -h <public_hostname> 
    exit 
   ```

1. Copy the key, cert, and `shibboleth2.xml` files out of the container (and remove the container)
    ```console
    $ docker container cp grouper:/etc/shibboleth/shibboleth2.xml .
    $ docker container cp grouper:/etc/shibboleth/sp-cert.pem .
    $ docker container cp grouper:/etc/shibboleth/sp-key.pem .

    $ docker container rm grouper
    ```
    
1. After updating the `shibboleth2.xml` file, save the key, cert, and shibboleth2.xml as secrets/config:
    ```console
    $ docker secret create sp-key.pem sp-key.pem
    $ docker config create sp-cert.pem sp-cert.pem
    $ docker config create shibboleth2.xml shibboleth2.xml
    ```

1. Add the following to the UI service creation command to mount the environment specific settings:
    ```
      --secret source=sp-key.pem.pem,target=shib_sp-key.pem \
      --config source=sp-cert.pem,target=/etc/shibboleth/sp-cert.pem \
      --config source=shibboleth2.xml,target=/etc/shibboleth/shibboleth2.xml \
    ```

# Logging

This image outputs logs in a manner that is consistent with Docker Logging. Each log entry is prefaced with the submodule name (e.g. shibd, httpd, tomcat, grouper), the logfile name (e.g. access_log, grouper_error.log, catalina.out) and user definable environment name and a user definable token. Content found after the preface will be specific to the application ands its logging configuration.

> Note: If customizing a particular component's logging, it is recommended that the file be source from the image (`docker container cp`) or from the image's source repository. 

To assign the "environment" string, set the environment variable `ENV` when defining the Docker service. For the "user defined token" string, use the environment variable of `USERTOKEN`.

An example might look like the following, with the env of "dev" and the usertoken of "build-2"

```text
shibd shibd.log dev build-2 2018-03-27 20:42:22 INFO Shibboleth.Listener : listener service starting
grouper-api grouper_event.log dev build-2 2018-03-27 21:10:00,046: [DefaultQuartzScheduler_Worker-1] INFO  EventLog.info(156) -  - [fdbb0099fe9e46e5be4371eb11250d39,'GrouperSystem','application'] session: start (0ms)
tomcat console dev build-2 Grouper starting up: version: 2.3.0, build date: null, env: <no label configured>
``` 

# Misc Notes

- [HTTP Strict Transport Security (HSTS)](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security) is enabled on the Apache HTTP Server.
- morphStrings functionality in Grouper is supported. It is recommended that the various morphString files be associated with the containers as Docker Secrets. Set the configuration file properties to use `/var/run/secrets/secretname`.
- Grouper UI has been pre-configured to authenticate users via Shibboleth SP. 
- By default, Grouper WS (hosted by `/opt/tomcat/`) and the Grouper SCIM Server (hosted by `/opt/tomee/`) use tomcat-users.xml for authentication, but by default no users are enabled. LDAP-backed authentication or other methods can be used and must be configured by the deployer.

# License

View [license information](https://www.apache.org/licenses/LICENSE-2.0) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
