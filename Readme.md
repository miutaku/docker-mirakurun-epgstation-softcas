# mirakurun(softcas)+epgstaion on docker

使う場合は自己責任で使う。

## command

Mirakurunは家にチューナーがある関係で家で、それ以外はクラウドにて実行する。

### mirakurun node
```shell
$ docekr login
$ docker compose -f docker-compose-mirakurun.yml up
```

### OCI instance
```shell
$ docker compose -f docker-compose-epgstation.yml up
```
