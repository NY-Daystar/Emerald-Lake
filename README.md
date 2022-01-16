# Emerald-Lake

Save the history of a server by creating a file history using ls -R command  
Developped in Bash v5.0.17

- [Get Started](#get-started)
- [How to use](#how-to-use)
- [Script options](#script-options)
- [Trouble-shootings](#trouble-shootings)
- [Credits](#credits)

#### Version v1.0.0

## Get Started

TODO a tester le clone et l'utilisation

```bash
$ git clone https://github.com/LucasNoga/Emerald-Lake.git
$ cd Emerald-Lake
```

Then create your configuration file **settings.conf**

```bash
$ touch settings.conf
$ vim settings.conf
```

Put this into the file with your server intels

```bash
REGISTRY=XX.XX.XX.XX
```

- REGISTRY (mandatory) : Registry to push image if you have a dockerhub account or github or gitlab registry

Example

```bash
REGISTRY=localhost:5050
```

## How to use

```bash
$ chmod +x emerald-lake.sh
$ cp settings.sample.conf settings.conf
$ ./emerald-lake.sh ~/.emerald-lake.sh
```

You can also create an alias

```bash
$ cp ./emerald-lake.sh
$ vim ~/.bashrc
```

Then add this to your file
`alias emerald-lake='~/.emerald-lake.sh'`

After that go to the root repo where you have a Dockerfile who builds a docker image and do

```bash
$ emerald-lake
```

Now follow CLI instructions to build and/or push the image

## Script options

Display debug mode

```bash
$ ./emerald-lake.sh --debug
$ ./emerald-lake.sh -d
```

Activate quiet mode

```bash
$ ./emerald-lake.sh --quiet
$ ./emerald-lake.sh -q
```

Show configuration file

```bash
$ ./emerald-lake.sh -c
$ ./emerald-lake.sh --config
$ ./emerald-lake.sh --show-config
```

Edit configuration file

```bash
$ ./emerald-lake.sh -s
$ ./emerald-lake.sh --setup
$ ./emerald-lake.sh --setup-config
```

## Trouble-shootings

If you have any difficulties, problems or enquiries please let me an issue [here](https://github.com/LucasNoga/Emerald-Lake/issues/new)

## Credits

Made by Lucas Noga  
Licensed under GPLv3.
