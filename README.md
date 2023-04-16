# XboxDevFileTools
Tools for interacting with the Xbox dev mode HTTPS-based file system API

For now, this is just a zsh script to upload the contents of a directory to a given remote location on the Xbox without recursion.  I might do more with it later.

Usage:

```
./upload_directory_to_xbox.zsh --username YOUR_HTTPS_API_USER --password YOUR_HTTPS_API_PASSWORD --hostname YOUR_XBOX_HOSTNAME_OR_IP_ADDRESS --local-directory "DIRECTORY_TO_LOCAL_FILES" --remote-directory "DIRECTORY_TO_REMOTE_LOCATION"
```

The remote location is assumed to be located in `User Files`, with a `/` as a path separator.  A sample valid remote location would be: `LocalAppData/jazz2.resurrection_1.8.0.386_x64__95k39fsjmdww6/LocalState/Source`.