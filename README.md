# Demo Puppet WebLogic implementation

This repo contains a demonstration of a Oracle Fusion SOA suite installation. It's purpose is to help you guide through an initial installation of an Oracle SOA node with Puppet. This demo is ready for Puppet 4 and for Puppet 5.

## Starting the nodes masterless

All nodes are available to test with Puppet masterless. To do so, add `ml-` for the name when using vagrant:

```
$ vagrant up ml-soa<version>n1
```

and/or

```
$ vagrant up ml-soa<version>n2
```

This dem support's WebLogic and SOA suite versions:
- 12.2.1.3
- 12.2.1.4

## Staring the nodes with PE

You can also test with a Puppet Enterprise server. To do so, add `pe-` for the name when using vagrant:

```
$ vagrant up pe-wlsmaster
$ vagrant up pe-wls1
```

## ordering

To succesfully run a SOA suite, You must have a database server for the Reprository (RCU). This demo contains a database server on node rcudb. You must always start this node first. You must always use the specified order:

1. wlmaster (When using PE)
2. rcu
3. soa<version>n1
4. soa<version>n2

## Required software

The software must be placed in `modules/software/files`. It must contain the next files:

### Puppet Enterprise

- puppet-enterprise-2017.2.3-el-7-x86_64-x86_64.tar.gz (Extracted tar)

### Oracle WebLogic 12.2.1.3

- jdk-8u161-linux-x64.tar.gz
- fmw_12.2.1.3.0_infrastructure.jar
- fmw_12.2.1.3.0_soa.jar.zip
- jce_policy-8.zip

### Oracle WebLogic 12.2.1.4

- jdk-8u231-linux-x64.tar.gz
- fmw_12.2.1.4.0_infrastructure.jar
- fmw_12.2.1.4.0_soa.jar.zip
- jce_policy-8.zip

You can download these files from
[here](http://support.oracle.com)
