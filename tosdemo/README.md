# tosdemo
DOS-style Intro/ Demo for TempleOS

* TempleOS    http://www.templeos.org/

[![tosdemo](http://i.imgur.com/VEjXp33.png)](https://www.youtube.com/watch?v=zyvwpRNWWfA)

PC speaker sound needs high-precision timing; probably won't work well in a VM. Caveat emptor.

There's a bootable ISO under Releases, burn a CD, boot native, and 

```
    Cd("Demo");
    #include "Demo";
```

The background music spawns a task on CPU#2, you can change that if you'd like by download the ISO.C or cloning the repo. To install to hard disk from the ISO.C:

```
    #include "Install";
```

will install to the `::/Apps/tosdemo` directory.

Requires HPET, you might need to enable in your VM config, example (for VirtualBox):

```
   VBoxManage modifyvm "vm_name" --hpet on
```

Enjoy!
