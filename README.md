# Unity Auto Build
**Unity Auto Build** is a trivial bash script that automatically builds Unity
project targets. With one command, the script builds all the target configured
in the XML config file.

## Overview
The script manages a working directory for the project much like git does.
In the working directory, the script performs `git fetch` and `git reset` to the
specified git spec(tag/branch/commit-id) and then Unity build commands.
After Unity build commands are executed, the script proceeds to compress
the output directories as needed.

In a working directory exist `git` directory and `UnityAutoBuild.xml` file.
The `git` directory is a bare git repository the script manages, and the xml
file is the configuration file that you can use to configure the script's
behaviour. Note that the main script(`uab-build`) takes no parameter.
The script is controlled via environment variables and the config XML file.

It is the user's job to program additional works like copying the output
binaries or mailing the result.

## Target Audience
This project is designed for Unix-savvy techies and not very user-friendly.
If you are not even familiar with CUI, this is not your cup of tea.

## Walk-through
This script should run on all Unix-like systems that have bash.

If you're planning to set up the environment on linux, you can get the
**linux version** of Unity from the link.

* https://forum.unity.com/threads/unity-on-linux-release-notes-and-known-issues.350256/

The linux version is currently alpha(and will probably be forever). So, expect
that something could go wrong when building on linux.

Unity also works on a machine running without GUI(no display server running).
In other words, the script can be placed and run on cloud linux instances like
AWS EC2 or GCP Compute Engine. However, setting up a Unity build environment on
such machines is a daunting and tedious task. So, if that's what you're looking
for, please refer to [the separate documentation](doc/Unity-without-GUI.md).

### Add Editor Scripts to Unity Project
For the script to build the Unity project, the editor C# scripts and its
dependency DLLs must be present in the project. Copy these files to your
project's asset directory.

* `/UnityAutoBuild.unity/Assets/_export/*.cs`
* `/UnityAutoBuild.unity/Assets/_modules/*.dll`

### Packages Required by the Script
Following tools are used by the script. Ensure that the system running the
script has them.
```
git libxml2 zip tar xz gzip
```

### Install the Program
Clone the git project to anywhere you think it's appropriate. In this document,
`/opt` path is used.
```
git clone https://github.com/fixstu/UnityAutoBuild /opt/UnityAutoBuild
```

Set the PATH. In `~/.bash_profile`, add the following line before `EXPORT PATH`.
```
PATH="$PATH:/opt/UnityAutoBuild"
```

You can always skip this step and go on using the script by specifying the full
path of the script(`/opt/UnityAutoBuild/...` in this case). That's perfectly
fine.

### Set a Working Directory
The script is programmed to be run on its own structured working directory.
You can't run it on your working Unity project directory. Allocate a directory
for the script to operate on within a file system with enough space. In the
directory, run `uab-init <git repo url>` to populate the script's working
directory.
```
mkdir build-wd
cd build-wd
uab-init https://github.com/example/UnityProject
```

### Edit the Config XML
After populating the working directory, there'll be a file named
`UnityAutoBuild.xml` copied to the directory. This is a config file that
the script reads. You can start using by uncommenting the sample `<Config>`
tags, and that should just do. Continue to read the rest of this section for
advanced use.

The config file is validated before used by the script using
`UnityAutoBuild.xsd` file. If `xmllint` complains, it is worth reading
the schema to understand how the config file can be written.
Here's the description of the content.

* `<FetchSpec>`: git spec to build. Refer to `man git-fetch` for the definition
of '(ref)spec'.
* `<ProjectPath>`: If the unity project is located in subdirectory within
the repo, use this to specify its location. '/' at the start is not necessary.
Examples: `sub/unity`, `unity_project`
* `<Targets>`: Targets to build. Uncomment the targets to build.
  * `<Config>`: Represents a target configuration.
    * `id`: The config ID. This is used by the script only.
    * `base`: The base config. The base configs are pre-defined in
    `/UnityAutoBuild.unity/Assets/_export/BuildConfig.cs`. From the base configs,
    you can customise targets, just like ticking options checkboxes on
    the 'BuildSettings' Editor dialog by placing `<Prop>` tags(See below).
    * `out`: Output path. **This is the path to the output binary, not the output
    directory**(if the target generates output files in a subdirectory).
    Definition of "output path" by Unity is rather ambiguous.
    See [the appendix](#appendix-locationPathName)
    for more detail.
    * `<Bundler>`: When this tag is specified, the script will compress the
    generated output directory and delete it. You may want to use this for all
    PC targets.
    * `<Prop>`: `UnityEditor.BuildOptions` to override. Keep in mind that the
    base configs already define the build options, and this tag is to help
    you override them. Different set of build options are available for each
    target(eg: `SymlinkLibraries` is only for iOS target). Use with caution.
    Note that not all values of `UnityEditor.BuildOptions` are accepted because
    some of them are meaningful only when building on GUI mode.

### Run the Command!
You are now all set! Run command:
```
uab-build
```
Building takes some time. More if you configured several. When the command
returns, the output files will be placed in `builds/` directory. You can do
whatever you want to this directory(copy/tar/move/delete ...). Don't mind
keeping this directory in place because the script will delete it anyway before
issuing Unity build commands.

What happens when this command is issued?
1. Delete previously created `wd` and `build` directory and create them anew.
1. `cd` into `wd` directory and run `git fetch` and `git reset`.
1. Issue the Unity build commands one by one

For the third part, it is complicated as to how this process works. You might as
well read the code for an explanation.

Yes, the script deletes the checked out Unity project directory, deleting all
caches every time. **This is intentional**. Among the goal of the script is to
test if the clean checked out git repository can be built(dependency check).

It takes about **30 minutes** to build 4 targets(windows x86, linux universial,
linux headless, android) on a **c4.large** type EC2 instance.

## Appendix
### Influential Environment Variables
(defined in `_uab-internal.sh`)

* `UAB_CONF_XML`: Path to the config file. You can have several config
files(other than `UnityAutoBuild.xml`) and instruct the script to use one of
them like this:
```
UAB_CONF_XML="android-only.xml" uab-build
```
* `UAB_EXEC_UNITY`: Unity Editor command. If the Unity Editor is not in PATH
variable, you can explicitly specify it. The default value is `Unity`.

(other insignificant variables)

* `UAB_EXEC_XMLLINT`
* `UAB_EXEC_ZIP`
* `UAB_EXEC_XZ`
* `UAB_EXEC_TAR`

### Definition of `UnityEditor.BuildPlayerOptions.locationPathName`
<a name="appendix-locationPathName"/>
https://docs.unity3d.com/ScriptReference/BuildPlayerOptions.html

* When you build Windows target, the Unity Editor asks for the path to the
output director whereas when building other targets, it asks for the path to the
output binary. But in the C# API, `locationPathName` is always the path to the
output binary.
* When building `LinuxUniversial` target(which is the target of the
`base="LINUX"` attribute), `locationPathName` represents the prefix of the two
output binaries. So, notice that `out` attribute for the linux targets have
no file extension.
