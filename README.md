# bosh-meta-cpi-release

Colocate multiple bosh cpis.


For example the bosh-lite manifest for using aws and bosh-lite 
```yaml
---
name: bosh

releases:
- name: bosh
  url: https://bosh.io/d/github.com/cloudfoundry/bosh?v=256.7
  sha1: 6fa486378892737f5ad4409bcf4f122cb85c12d4
- name: bosh-aws-cpi
  url: https://bosh.io/d/github.com/cloudfoundry-incubator/bosh-aws-cpi-release?v=53
  sha1: 3a5988bd2b6e951995fe030c75b07c5b922e2d59
- name: bosh-meta-cpi
  url: file:///home/bosh-meta-cpi-release/dev_releases/bosh-meta-cpi/bosh-meta-cpi-0+dev.22.tgz
- name: bosh-warden-cpi
  url: https://bosh.io/d/github.com/cppforlife/bosh-warden-cpi-release?v=29
  sha1: 9cc293351744f3892d4a79479cccd3c3b2cf33c7
- name: garden-linux
  version: 0.337.0
  sha1: d1d81d56c3c07f6f9f04ebddc68e51b8a3cf541d
  url: https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release?v=0.337.0

resource_pools:
- name: vms
  network: private
  stemcell:
    url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3232.4
    sha1: ac920cae17c7159dee3bf1ebac727ce2d01564e9
  cloud_properties:
    instance_type: t2.micro
    ephemeral_disk: {size: 25_000, type: gp2}
    availability_zone: AVAILABILITY_ZONE # <--- Replace with Availability Zone

disk_pools:
- name: disks
  disk_size: 20_000
  cloud_properties: {type: gp2}

networks:
- name: private
  type: manual
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    dns: [10.0.0.2]
    cloud_properties: {subnet: SUBNET_ID} # <--- Replace with Subnet ID
- name: public
  type: vip

jobs:
- name: bosh
  instances: 1

  templates:
  - {name: nats, release: bosh}
  - {name: postgres, release: bosh}
  - {name: blobstore, release: bosh}
  - {name: director, release: bosh}
  - {name: health_monitor, release: bosh}
  - {name: registry, release: bosh}
  - {name: meta_cpi, release: bosh-meta-cpi}
  - {name: aws_cpi, release: bosh-aws-cpi}
  - {name: warden_cpi, release: bosh-warden-cpi}
  - {name: garden, release: garden-linux}

  resource_pool: vms
  persistent_disk_pool: disks

  networks:
  - name: private
    static_ips: [10.0.0.6]
    default: [dns, gateway]
  - name: public
    static_ips: [ELASTIC_IP] # <--- Replace with Elastic IP

  properties:
    nats:
      address: 127.0.0.1
      user: nats
      password: nats-password

    postgres: &db
      listen_address: 127.0.0.1
      host: 127.0.0.1
      user: postgres
      password: postgres-password
      database: bosh
      adapter: postgres

    registry:
      address: 10.0.0.6
      host: 10.0.0.6
      db: *db
      http: {user: admin, password: admin, port: 25777}
      username: admin
      password: admin
      port: 25777

    blobstore:
      address: 10.0.0.6
      port: 25250
      provider: dav
      director: {user: director, password: director-password}
      agent: {user: agent, password: agent-password}

    director:
      address: 127.0.0.1
      name: my-bosh
      db: *db
      cpi_job: meta_cpi
      max_threads: 10
      user_management:
        provider: local
        local:
          users:
          - {name: admin, password: admin}
          - {name: hm, password: hm-password}

    hm:
      director_account: {user: hm, password: hm-password}
      resurrector_enabled: true

    aws: &aws
      access_key_id: ACCESS_KEY # <--- Replace with AWS Access Key ID
      secret_access_key: SECRET_KEY # <--- Replace with AWS Secret Key
      default_key_name: bosh
      default_security_groups: [bosh]
      region: REGION  # <--- Replace with Region

    warden_cpi:
      host_ip: 10.0.0.6
      warden:
        connect_network: tcp
        connect_address: 127.0.0.1:7777
      agent:
        mbus: nats://nats:nats-password@10.0.0.6:4222
        blobstore:
          provider: dav
          options:
            endpoint: http://10.0.0.6:25250
            user: agent
            password: agent-password

    # garden job template
    garden:
      listen_network: tcp
      listen_address: 0.0.0.0:7777
      disk_quota_enabled: false
      allow_host_access: true
      destroy_containers_on_start: true # avoids snapshots
      default_container_grace_time: 0

    agent: {mbus: "nats://nats:nats-password@10.0.0.6:4222"}

    ntp: &ntp [0.pool.ntp.org, 1.pool.ntp.org]

cloud_provider:
  template: {name: aws_cpi, release: bosh-aws-cpi}

  ssh_tunnel:
    host: ELASTIC_IP # <--- Replace with your Elastic IP address
    port: 22
    user: vcap
    private_key: ./bosh.pem # Path relative to this manifest file

  mbus: "https://mbus:mbus-password@ELASTIC_IP:6868" # <--- Replace with Elastic IP

  properties:
    aws: *aws
    agent: {mbus: "https://mbus:mbus-password@0.0.0.0:6868"}
    blobstore: {provider: local, path: /var/vcap/micro_bosh/data/cache}
    ntp: *ntp


```
