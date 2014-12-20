## Oracle Database 11.2.0.4 with ASM on NFS

The reference implementation of https://github.com/biemond/biemond-oradb
optimized for linux, solaris

ASM is based on NFS

### Software ( 11.2.0.4 )
- p13390677_112040_Linux-x86-64_1of7.zip db file 1
- p13390677_112040_Linux-x86-64_2of7.zip db file 2
- p13390677_112040_Linux-x86-64_3of7.zip grid
- p6880880_112000_Linux-x86-64.zip opatch upgrade
- p19791420_112040_Linux-x86-64.zip opatch bundle patch

### Vagrant
Update the vagrant /software share to your local binaries folder

Startup the box
- vagrant up dbasm

Login
- vagrant ssh dbasm

### Accounts
- root password vagrant
- vagrant password vagrant, has sudo rights
- grid password oracle
- oracle password oracle

