# Apache Apisix

> https://github.com/apache/apisix-dashboard


- docker build

```shell
APISIX_DASHBOARD_VERSION=v2.2 && docker build --build-arg APISIX_DASHBOARD_VERSION=${APISIX_DASHBOARD_VERSION} -t dickens7/apisix-dashboard:${APISIX_DASHBOARD_VERSION} .
```