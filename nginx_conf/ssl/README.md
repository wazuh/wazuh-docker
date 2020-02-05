
### Enable SSL Traffic

Our Nginx config has SSL enabled by default, but it does require you to provide your certificate first, copy here your certificate files as `kibana-access.pem` and `kibana-access.key`.

The final tree should be like this:

```
nginx_conf/
├── kibana.htpasswd
├── kibana-web.conf
└── ssl
    ├── kibana-access.key
    └── kibana-access.pem
```



#### Using a Self Signed Certificate

In case you want to use a self-signed certificate we provided a script to generate one.

Execute `bash generate-self-signed-cert.sh` on this same directory and the right files will be generated. You must have installed `openssl` locally.
