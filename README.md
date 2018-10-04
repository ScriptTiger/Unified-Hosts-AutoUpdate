[![Say Thanks!](https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg)](https://saythanks.io/to/ScriptTiger)

# Unified Hosts AutoUpdate
Quickly and easily install, uninstall, and set up automatic updates for any of Steven Black's unified hosts files.

This AutoUpdate project is maintained by ScriptTiger: https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate

The Unified Hosts project is maintained by Steven Black: https://github.com/StevenBlack/hosts

Further project contributors are noted with their contributions in the Unified Hosts data, both available online from Steven Black's project as well as in the data injected into the local hosts file by this script, as it is downloaded directly from Steven Black's most recently pre-generated Unified Hosts files.

You can download this repo from the below link to get started:  
https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate/archive/master.zip  
**There have been critical updates to how the script updates itself in order to make the process safer and more consistent. If your script is crashing or experiencing issues immediately after you execute it while it is trying to check its version, you will need to backup your ignore.txt and custom.txt and manually update your package either by redownloading the above ZIP file or using git.**

Extract the contents to the same directory and run the Hosts_Update.cmd script. There is also an option to remove the Unified Hosts from your local hosts file. In the event critical changes are made to either the AutoUpdate repo or to the Unified Hosts repo, this script is also capable of automatically updating itself.

**If you experience problems with performance or seemingly unrelated networking issues after running this script, please try adjusting your compression level to one that best suits your needs.**

**If you're running Windows XP or Windows Sever 2003 and don't have Background Intelligent Transfer Service (BITS) installed, please visit the following link first to find out how to install it. BITS is REQUIRED by this script to function in order to eliminate the need for third-party applications and keep everything native to Microsot Windows.  
https://support.microsoft.com/en-us/help/923845/an-update-package-for-background-intelligent-transfer-service-bits-is**

If you want to ignore or whitelist certain entries from the Unified Hosts and prevent them from appearing in your local hosts, just add them to the ignore.txt. These entries are made with literal expressions and can match all or only part of an entry. So if you want to only ignore one specific URL, it's better to put the whole line just in case. For example, if you want to ignore the `www.google.com` domain specifically, put this:  
`0.0.0.0 www.google.com`  
If you want to ignore all .de websites, you can simply put:  
`.de`  
If you want to ignore all subdomains of google.com, you can put:  
`.google.com`  
If you want to ignore all google subdomains in any top level domain:  
`.google.`

If you would also like to manage custom hosts file entries with this script, you can do so using the custom.txt. As this script does not alter custom entries in the hosts file itself, this is simply an option to make things easier if you would prefer to manage custom entries this way rather than manually managing them in the hosts file.

Also, if you send your preferred URL to the script as a parameter, it will bypass all the prompts and automatically install/update the Unified Hosts in the local hosts file. This is useful for things like scheduling a task to update your Unified Hosts daily or weekly, etc. You can even update your hosts randomly throughout the day at certain times to switch between Unified Hosts to, for example, only allow social in the evenings or on the weekends. If you do decide to make a scheduled task, also remember the account issuing the task must still have administrative privileges to be able to write to the local hosts file. You can optionally add your preferred compression level as a second parameter, as well, but this must always accompany a URL as the first parameter.

Because no backup of your local hosts file is needed, entries in the Unified Hosts relating to the localhost and other loopback addresses have been removed to prevent possible conflict with preexisting entries. No backup is needed because this script implements the Unified Hosts within opening and closing tags to clearly segment it from the user's preexisting entries and allow the script to know what area of the file to overwrite during an update or remove during removal.

If you are deploying the update script across an organization via a shared network location and group policies, edit the "VERSION" file by adding an X to the end of the version number like this:  
1.10X  
This will disable the script from checking for script updates and attempting to update itself. This does not affect updates to the hosts file or whatever scheduled tasks you may have in place, this strictly disables the Hosts_Update.cmd from updating itself within the shared network location which remote system accounts running the scheduled tasks may not have write access to.

**This script is in active development, so please share your feedback on what you like and don't like so we know what direction to take and don't inadvertently make things worse**

For more ScriptTiger scripts and goodies, check out ScriptTiger's GitHub Pages website:  
https://scripttiger.github.io/

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MZ4FH4G5XHGZ4)

Donate Monero (XMR): 441LBeQpcSbC1kgangHYkW8Tzo8cunWvtVK4M6QYMcAjdkMmfwe8XzDJr1c4kbLLn3NuZKxzpLTVsgFd7Jh28qipR5rXAjx
