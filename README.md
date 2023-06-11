[![Say Thanks!](https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg)](https://docs.google.com/forms/d/e/1FAIpQLSfBEe5B_zo69OBk19l3hzvBmz3cOV6ol1ufjh0ER1q3-xd2Rg/viewform)

# Unified Hosts AutoUpdate
Quickly and easily install, uninstall, and set up automatic updates for any of Steven Black's unified hosts files.

This AutoUpdate project is maintained by ScriptTiger: https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate

The Unified Hosts project is maintained by Steven Black: https://github.com/StevenBlack/hosts

Further project contributors are noted with their contributions in the Unified Hosts data, both available online from Steven Black's project as well as in the data injected into the local hosts file by this script, as it is downloaded directly from Steven Black's most recently pre-generated Unified Hosts files.

You can download this repo from the below link to get started:  
https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate/archive/master.zip  
**If your script worked in the past but has stopped working since, please update your repo files and try again before posting a new issue.**

Extract the contents to the same directory and run the Hosts_Update.cmd script. There is also an option to remove the Unified Hosts from your local hosts file. In the event critical changes are made to either the AutoUpdate repo or to the Unified Hosts repo, this script is also capable of automatically updating itself.

**If you experience problems with performance or seemingly unrelated networking issues after running this script, please try adjusting your compression level to one that best suits your needs.**

**This script requires either BITS or PowerShell to function. While both are native to modern Microsoft Windows installations, there are also compatible versions which can be manually installed for older systems.**

If you want to ignore or whitelist certain entries from the Unified Hosts and prevent them from appearing in your local hosts, just add them to the ignore.txt. These entries are made with literal expressions and can match all or only part of an entry. So if you want to only ignore one specific URL, it's better to put the whole line just in case. For example, if you want to ignore the `www.google.com` domain specifically, put this:  
`0.0.0.0 www.google.com`  
If you want to ignore all .de websites, you can simply put:  
`.de`  
If you want to ignore all subdomains of google.com, you can put:  
`.google.com`  
If you want to ignore all google subdomains in any top level domain:  
`.google.`

If you would also like to manage custom hosts file entries with this script, you can do so using the custom.txt. As this script does not alter custom entries in the hosts file itself, this is simply an option to make things easier if you would prefer to manage custom entries this way rather than manually managing them in the hosts file.

Also, if you send your preferred URL to the script as a parameter, it will bypass all the prompts and automatically install/update the Unified Hosts in the local hosts file. This is useful for things like scheduling a task to update your Unified Hosts daily or weekly, etc. You can even update your hosts randomly throughout the day at certain times to switch between Unified Hosts to, for example, only allow social in the evenings or on the weekends. And if you would like to remove the Unified Hosts from your hosts file, you can just enter "remove" as the URL. If you do decide to make a scheduled task, also remember the account issuing the task must still have administrative privileges to be able to write to the local hosts file. You can optionally add your preferred compression level as a second parameter, as well, but this must always accompany a URL as the first parameter.

Because no backup of your local hosts file is needed, entries in the Unified Hosts relating to the localhost and other loopback addresses have been removed to prevent possible conflict with preexisting entries. No backup is needed because this script implements the Unified Hosts within opening and closing tags to clearly segment it from the user's preexisting entries and allow the script to know what area of the file to overwrite during an update or remove during removal.

If you are deploying the update script across an organization via a shared network location and group policies, edit the "VERSION" file by adding an X to the end of the version number like this:  
1.10X  
This will disable the script from checking for script updates and attempting to update itself. This does not affect updates to the hosts file or whatever scheduled tasks you may have in place, this strictly disables the Hosts_Update.cmd from updating itself within the shared network location which remote system accounts running the scheduled tasks may not have write access to.

By default, the script forces the command processor instance to close upon completion just to ensure you don't have an unattended command prompt with administrative permissions lingering where it's not needded. However, for debugging or other purposes you can send `/DFC` as an initial argument to prevent the command prompt from closing after script completion. For further debugging, please reference the following error code table.

By default, log entries are only kept from the most recent scheduled task in the  `log.txt` within the script home directory. If script updates are disabled, there will be no automatic logging since the assumption is the script directory is read-only. However, to force persistent logging to the script directory, you can also send `/LOG` as an initial argument to force writing a persistent log that always logs everything and never clears the log. You also have the option of alternatively using `/LOG:<file>` to write a persistent log to a directory and file of your choosing, which is recommended to be set to a local machine directory for deployments across networks so that logs are not written to the shared script directory which should be read-only. If you choose to configure persistent logging, please remember that managing that logging and associated file sizes then becomes your own responsibility.

**Please note, all initial arguments (`/DFC`,`/LOG:<file>`, etc.) must be placed before the URL and compression parameters (i.e. `Hosts_update.cmd /DFC <URL>`).**

Decimal Error Code | Hexadecimal Error Code | Explanation
-------------------|------------------------|-----------------------------------------------------------------------------------
0                  | 0x0                    | The operation completed successfully. (No errors)
1                  | 0x1                    | Must be run with administrative permissions
2                  | 0x2                    | "#### END UNIFIED HOSTS ####" not properly marked in hosts file
3                  | 0x3                    | Hosts file is not properly marked
4                  | 0x4                    | Currently disabled due to maintenance, please try again later
5                  | 0x5                    | Your system cannot connect to GitHub
6                  | 0x6                    | Neither BITS nor PowerShell installed
7                  | 0x7                    | Download mechanism cannot connect to GitHub
8                  | 0x8                    | Download failed
255                | 0xFF                   | The script terminated unexpectedly

**This script is in active development, so please share your feedback on what you like and don't like so we know what direction to take and don't inadvertently make things worse**

For more ScriptTiger scripts and goodies, check out ScriptTiger's GitHub Pages website:  
https://scripttiger.github.io/

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MZ4FH4G5XHGZ4)
