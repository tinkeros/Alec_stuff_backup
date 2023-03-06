# uriel
Uriel Web Browser for TempleOS

This is a proof-of-concept web browser for TempleOS.  
It is still very early stages.

![Uriel](http://i.imgur.com/CON0XzB.png "Uriel Web Browser")

Add the following to your `/etc/hgbdd.conf`:
```
    modules: {
        "uriel":"/path/to/uriel.py"
    }
```

In your `HomeKeyPlugIns.HC` or other startup script:
```
    #include "HGBD";
    #include "Uriel";
```

You can launch a Browser in the current Task with:
```
    U_Browser(url);
```

# Prerequisites

- Sup1Utils/FileBMP.HC.Z from Sup1 disc (for now)
- [HGBD](https://github.com/tramplersheikhs/hgbd)
- Beautiful Soup 4 (for DolDoc preprocessing) 
