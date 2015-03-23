# delivery-golang

Delivery Build Cookbook to build Golang Applications

Delivery Config File
------------

This is an example of the `.delivery/config.json` you should use to build a Golang Application.

```
{
  "version": "1",
  "build_cookbook": "delivery-golang",
  "skip_phases": [ "functional", "quality", "release", "security", "smoke" ],
  "build_attributes": {
    "golang": {
      "path": "github.com/chef/greentea",
      "packages": ["github.com/golang/lint/golint", "github.com/stretchr/testify"]
    },
    "publish": {
        "chef_server": true,
        "github": "chef/greentea"
    },
    "deploy": {
      "rolling": {
        "deploy-greentea": 20,
        "lb-greentea": 100,
        "audit": false
    }
  }
}
```

LICENSE AND AUTHORS
===================
- Author: Salim Afiune (<afiune@chef.io>)

