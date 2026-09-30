[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/apache/apisix/blob/master/LICENSE)
![Version](https://img.shields.io/static/v1?label=Openldap&message=2.6.10&color=blue)

# OpenLDAP Helm Chart

## Prerequisites Details
* Kubernetes 1.8+
* PV support on the underlying infrastructure

## Chart Details
This chart will do the following:

* Instantiate 3 instances of OpenLDAP server with mirror-mode replication
* A phpldapadmin to administrate the OpenLDAP server
* ltb-passwd for self service password based on the official container image

**Now provide read-only feature !** [more details](#read-only)

## TL;DR

To install the chart with the release name `my-release`:

```bash
$ helm repo add helm-openldap https://reprostat.github.io/helm-openldap/
$ helm install my-release helm-openldap/openldap-stack-ha
```


## Configuration

We use the container images provided by https://github.com/vegardit/docker-openldap. The container image is highly configurable and well documented. Please consult to documentation of the image for more information.

The following table lists the configurable parameters of the openldap chart and their default values.

TODO

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install --name my-release -f values.yaml stable/openldap
```

> **Tip**: You can use the default [values.yaml](values.yaml)


## PhpLdapAdmin
To enable PhpLdapAdmin set `phpldapadmin.enabled`  to `true`

Ingress can be configure if you want to expose the service.
Setup the env part of the configuration to access the OpenLdap server

**Note** : The ldap host should match the following `namespace.Appfullname`

Example :
```
phpldapadmin:
  enabled: true
  ingress:
    enabled: true
    annotations: {}
    # Assuming that ingress-nginx is used
    ingressClassName: nginx
    path: /
    ## Ingress Host
    hosts:
    - phpldapadmin.local
  env:
    PHPLDAPADMIN_LDAP_CLIENT_TLS_REQCERT: "never"

```
## Self-service-password
To enable Self-service-password set `ltb-passwd.enabled`  to `true`

Ingress can be configure if you want to expose the service.

Setup the `ldap` part with the information of the OpenLdap server.

Set `bindDN` accordingly to your ldap domain

**Note** : The ldap server host should match the following `ldap://namespace.Appfullname`

Example :
```
ltb-passwd:
  enabled : true
  ingress:
    enabled: true
    annotations: {}
    # Assuming that ingress-nginx is used
    ingressClassName: nginx
    host: "ssl-ldap2.local"

```

## Cleanup orphaned Persistent Volumes

Deleting the Deployment will not delete associated Persistent Volumes if persistence is enabled.

Do the following after deleting the chart release to clean up orphaned Persistent Volumes.

```bash
$ kubectl delete pvc -l release=${RELEASE-NAME}
```

## Custom Secret

`global.existingSecret` can be used to override the default secret.yaml provided

## Scaling your cluster
In order to scale the cluster, first use `helm` to updrgade the number of `replica`
```
helm upgrade -n openldap-ha --set replicaCount=4 openldap-ha .
```
Then connect to the `<openldap>-0` container, under `/opt/bitnami/openldap/etc/schema/`, edit :
 1. `serverid.ldif` and remove existing `olcServerID` (only keep the one you added by scaling)
 2. `brep.ldif` and remove existing `olcServerID` (only keep the one you added by scaling)
 3. Apply your changes

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/serverid.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/brep.ldif
```

Tips : to edit in the container, use :
```
cat <<EOF > /tmp/serverid.ldif
copy
your
line
EOF
```

## Read Only

By setting `readOnlyReplicaCount` to `1` or more, you turn on the `read-only` cluster.

This create a `read-only` statefullset that replicates data against the main nodes. 
> [!WARNING]  
> Schemas are not replicated, so make sure every schemas are defined in `customSchemaFiles`

Main nodes are not aware of the `read-only` cluster so that failures in `read-only` nodes don't have any impact on the `main` cluster. 

This feature uses the `olcReadOnly: TRUE` directive 
> This directive puts the database into "read-only" mode. Any attempts to modify the database will return an "unwilling to perform" error. 
> If set on a consumer, modifications sent by syncrepl will still occur.


## Troubleshoot

You can increase the level of log using `env.LDAP_LOGLEVEL`

Valid log levels can be found [here](https://www.openldap.org/doc/admin24/slapdconfig.html)

### Boostrap custom ldif

**Warning** when using custom ldif in the `customLdifFiles` or `customLdifCm` section you  have to create the high level object `organization`

```
dn: dc=test,dc=example
dc: test
o: Example Inc.
objectclass: top
objectclass: dcObject
objectclass: organization
```

**note** the admin user is created by the application and should not be added as a custom ldif

All internal configuration like `cn=config` , `cn=module{0},cn=config` cannot be configured yet.

## Changelog/Updating

### To 4.x 
- Extra schema are supported (examples can be found [here](https://github.com/reprostat/helm-openldap/tree/main/advanced_examples) and [here](https://github.com/reprostat/helm-openldap/blob/main/.bin/myval.yaml)
- Feature read-only nodes
- TLS can be enforced for the replication
- Use a forked version of Bitnami available [here](https://github.com/reprostat/openldap-container) because of this [issue](https://github.com/bitnami/containers/pull/53960)

### To 4.0.0

This major update switch the base image from [Osixia](https://github.com/osixia/docker-openldap) to [Bitnami Openldap](https://github.com/bitnami/containers/tree/main/bitnami/openldap)

- Upgrade may not work fine between `3.x` and `4.x`
- Ldap and Ldaps port are non privileged ports (`1389` and `1636`)
- Replication is now purely setup by configuration
- Extra schema cannot be added/modified

A default tree (Root organisation, users and group) is created during startup, this can be skipped using `LDAP_SKIP_DEFAULT_TREE` , however you need to use `customLdifFiles` or `customLdifCm` to create a root organisation.

- This will be improved in a future update.

### To 3.0.0

This major update of the chart enable new feature for the deployment such as :

- supporting initcontainer
- supporting sidecar
- use global parameters to ease the configuration of the app
- out of the box integration with phpldapadmin and self-service password in a secure way
