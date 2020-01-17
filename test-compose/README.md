The `test-compose` directory contains an example Grouper environment that starts up the various Grouper components. This example demonstrates how one might go about customizing and deploying their Grouper containers, using the TIER Grouper image as a base image. 

In this example, the following cases are covered by this example:

- A demo directory and SIS database are included, populated with approximately 1,000 test subjects.
- Grouper is configured to use this directory as the subject source.
- Grouper Loader creates groups based on the data in the SIS table.
- Grouper UI is protected by a Shibboleth IdP (included) that connects to this directory server.
- Grouper WS is protected by http basic auth that authenticates against the directory server.
- Grouper publishes event data to a RabbitMQ instance (included). 

It should be noted that while this example uses Docker Compose as a build and deployment vehicle, ideally one should use a CI server to build and publish institution specific images to an image repository as changes to the institution's customizations are committed to the source repository. These images would then be deployed to Docker Swarm, assuming that the appropriate Docker Secrets and Configs have been published to the swarm.

# Getting Started

From `test-compose` directory, run:

```console
$ docker-compose up -d
```

This will build each of our customized images after downloading the TIER Grouper image. It will create containers for each of our components using the configuation specified in the `docker-compose.yml` file.

To stop the Grouper environment, run:

```console
$ docker-compose down
```

When doing iterative work, such as testing UI changes or configuration changes, I find if handy to use the following command:

```console
$ docker-compose kill; docker-compose rm -f; docker-compose build && docker-compose up
```

This command will clear out any remaining containers, as defined by the `docker-compose.yml` file, from the Docker host, rebuild our custom images, and start new instances of them. Because we do not specify the `-d` on the `up` command, the containers will not be forked causing the container logs to be displayed to the console, and the command prompt will not return until hitting `Ctrl+C`, which will kill the running containers.

# Testing Endpoints

The components can be accessed at the following urls, with

Grouper UI: https://localhost/grouper (username: banderson, password: password (from ldap) or password1 (from tomcat-users.xml))
Grouper WS: https://localhost:8443/grouper-ws/status?diagnosticType=all
Grouper SCIM: https://localhost:9443/grouper-ws-scim/ (username: banderson, password: password (from tomcat-users.xml))
RabbmitMQ: http://localhost:15672/ (username: guest, password: guest) 
MariaDB: Port 3306 (username: root, password: (no password) )
389-ds Directory: Port 389 (username: cn=Directory Manager, password: password)

Note that when accessing the Grouper UI, Grouper WS, or Shibboleth IdP, your browser will prompt you about an untrusted certificate. It is OK to ignore the warning while working with this example configuration.

# Additional Notes

- In this example, we use a variety of ways to pass in passwords (Grouper database, LDAP, Grouper Client, and RabbitMQ). The point is to demonstrate possibilities and not demonstrating what is required. (See the image readme for more details.)
- Docker `configs` are not supported by Docker Compose (when run in a non-Swarm mode), so those are represented in the `docker-compose.yml` file as bind mount volumes.
- The Grouper config files in the `data` image's `conf` directory are used to build the sample grouper database and ldap store. They are not used when the container is instantiated as there is no Grouper runtime in this container.
- The containers will use Docker Secrets and bind mounts for non-sensitive files that are read from the `configs-and-secrets` directory in the `test-compose` directory.
- With regard to RabbitMQ, the deployer must manually add a queue named `sampleQueue` to see Grouper messages in RabbitMQ. Messages will be dropped by RabbitMQ (and the Grouper Deamon will log errors) until this occurs.
- In this example, we don't care about the IdP secrets. They are baked into the overlay instead of using Docker Secrets. (This is not best practice for an IdP configuration, but that isn't the focus of this example.)

# Future TODOs

- Add a Docker Stack example

> This docker-stack.yml file uses the `configs` syntax which is part of the Compose file format v3.3 and requires Docker Engine version 17.06.0+ (released on 2017-06-28). Users of older engine versions will need convert `config` references to use bind mounts. After this change, everything else should work as expected.
