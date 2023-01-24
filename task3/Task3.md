# Task 3

Docker Image `atactr/devops-assignment:1.0.0` (https://hub.docker.com/r/atactr/devops-assignment/tags) is having some network issues.

Please fix the network issue and share with us the process and root cause of the issue

# Deep dive into docker container

- Start the docker and connect to `bash`

 `docker run --rm --name test -it --privileged --platform linux/amd64 atactr/devops-assignment:1.0.0 bash`

- Check `/root/hack` file, 

	```bash
	[root@04b1f9b6863d ~]# ./hack
	2023/01/24 06:23:27 exit status 3
	```

`exit status 3` is no meaningful error, so I will try to run `curl` inside the container.

 ```bash
 [root@04b1f9b6863d ~]# if curl 'https://www.google.com' > HTML_Output
 > then echo "Request was successful"
 > else echo "CURL Failed"
 > fi
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
								Dload  Upload   Total   Spent    Left  Speed
 100 15741    0 15741    0     0  17818      0 --:--:-- --:--:-- --:--:-- 17989
 Request was successful
 ```

- Check network inspection for make sure that normal ?????????
 ```json
 "NetworkSettings": {
    "Bridge": "",
    "SandboxID": "a76e8a25f2acb8447f531e00a525798a3740b68410eeb79b37543521c007d204",
    "HairpinMode": false,
    "LinkLocalIPv6Address": "",
    "LinkLocalIPv6PrefixLen": 0,
    "Ports": {},
    "SandboxKey": "/var/run/docker/netns/a76e8a25f2ac",
    "SecondaryIPAddresses": null,
    "SecondaryIPv6Addresses": null,
    "EndpointID": "17cce93073a7d5754f499514cf230ac62af65842d567c886e4294ed5f87847c8",
    "Gateway": "172.17.0.1",
    "GlobalIPv6Address": "",
    "GlobalIPv6PrefixLen": 0,
    "IPAddress": "172.17.0.2",
    "IPPrefixLen": 16,
    "IPv6Gateway": "",
    "MacAddress": "02:42:ac:11:00:02",
    "Networks": {
        "bridge": {
            "IPAMConfig": null,
            "Links": null,
            "Aliases": null,
            "NetworkID": "d0552f52c60254169ae92796db667ac441bf5ed1c3ec4e3ac8c67fd0a339dcc3",
            "EndpointID": "17cce93073a7d5754f499514cf230ac62af65842d567c886e4294ed5f87847c8",
            "Gateway": "172.17.0.1",
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "MacAddress": "02:42:ac:11:00:02",
            "DriverOpts": null
        }
    }
 }
 ```

# Problem

- `hack` is implemented, this file print exit code and exit container.

# Fix

- Remove `hack` from docker image.

 ```Dockerfile
 FROM atactr/devops-assignment:1.0.0
 WORKDIR /root/
 RUN rm -rf /root/hack
 CMD ["/bin/bash"]
 ```