# mysql-auto-failover

This is a vagrant image which will start a 3 node mysql cluster which is highly available.

### Prerequisite

* Virtualbox
* Vagrant

### Start the environment

This will load 4 virtual servers:

* Node A (Initial Master)
* Node B (Slave)
* Node C (Slave)
* Controller (Manages Failover)

To start the start the servers do:

```
vagrant up
```

### Failover Tutorial

Connect to the Controller and check that the nodes are clustered:

```
vagrant ssh controller
sudo bash
cat log.txt
```

This should then report the following:

```
2015-08-12 07:39:27 AM INFO Getting health for master: 192.168.33.10:3306.
2015-08-12 07:39:27 AM INFO Health Status:
2015-08-12 07:39:27 AM INFO host: 192.168.33.10, port: 3306, role: MASTER, state: UP, gtid_mode: ON, health: OK
2015-08-12 07:39:27 AM INFO host: 192.168.33.20, port: 3306, role: SLAVE, state: UP, gtid_mode: ON, health: OK
2015-08-12 07:39:27 AM INFO host: 192.168.33.30, port: 3306, role: SLAVE, state: UP, gtid_mode: ON, health: OK
```

This has shown that 192.168.33.10 is the current master and .20 and .30 are the slaves.

Exit out of the controller virtual machine.

To prove replication is working lets add a database to node A (the current master).

```
vagrant ssh A
mysql -uroot -ppassword
CREATE DATABASE failovertest;
SHOW DATABASES;
```

This will return a result of:

```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| failovertest       |
| mysql              |
| performance_schema |
+--------------------+
```

Now exit out of node A SSH ('exit' will close the mysql prompt) and connect to node B to check that it as automatically replicated the data.

```
vagrant ssh B
mysql -uroot -ppassword
SHOW DATABASES;
```

This will then return an identical query result:

```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| failovertest       |
| mysql              |
| performance_schema |
+--------------------+
```

Now exit out of node B SSH.

(If you want, you can repeat this with node C to prove it has replicated to all slaves)

Now to trigger a failover, we will stop the mysql service on node A.

```
vagrant ssh A
sudo service mysql stop
```

This will stop the mysql service on the master, if you exit this and connect to the controller, then you will see the updated status.

```
vagrant ssh controller
sudo bash
cat log.txt
```

This should then report:

```
2015-08-12 07:45:54 AM INFO Master may be down. Waiting for 3 seconds.
2015-08-12 07:46:09 AM INFO Failed to reconnect to the master after 3 attemps.
2015-08-12 07:46:09 AM CRITICAL Master is confirmed to be down or unreachable.
2015-08-12 07:46:09 AM INFO Failover starting in 'auto' mode
2015-08-12 07:46:09 AM INFO Candidate slave 192.168.33.20:3306 will become the new master.
...
2015-08-12 07:46:32 AM INFO Getting health for master: 192.168.33.20:3306.
2015-08-12 07:46:32 AM INFO Health Status:
2015-08-12 07:46:32 AM INFO host: 192.168.33.20, port: 3306, role: MASTER, state: UP, gtid_mode: ON, health: OK
2015-08-12 07:46:32 AM INFO host: 192.168.33.30, port: 3306, role: SLAVE, state: UP, gtid_mode: ON, health: OK
```

Now you can repeat the data replication tasks by connecting to node B and making a change and checking that is appears on node C.


### Issues

* If the master goes down, when it comes back up it doesn't rejoin the cluster. I haven't explored this enough to understand why and how to resolve.
