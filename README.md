# Unified Hosts AutoUpdate
Quickly and easily install, unsinstall, and set up automatic updates for any of Steven Black's unified hosts files.

This AutoUpdate project is maintained by ScriptTiger: https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate

The Unified Hosts project is maintained by Steven Black: https://github.com/StevenBlack/hosts

Wget is also a component to this project licensed separately in accordance with its attached documentation.

Further project contributors are noted with their contributions in the Unified Hosts data, both available online from Steven Black's project as well as in the data injected into the local hosts file by this script, as it is downloaded directly from Steven Black's most recently pre-generated Unified Hosts files.

You can download this repo from the below link to get started:  
https://github.com/ScriptTiger/Unified-Hosts-AutoUpdate/archive/master.zip

Extract the contents to the same directory and run the Hosts_Update.cmd script. There is also an option to remove the Unified Hosts from your local hosts file. In the event critical changes are made to either the AutoUpdate repo or to the Unified Hosts repo, this script is also capable of automatically updating itself.

If you want to ignore or whitelist certain entries from the Unified Hosts and prevent them from appearing in your local hosts, just add them to the ignore.txt. These entries are made with literal expressions and can match all or only part of an entry. So if you want to only ignore one specific URL, it's better to put the whole line just in case. If you want to ignore all .de websites, you can simply put:  
.de  
If you want to ignore all subdomains of google.com, you can put:  
.google.com  
If you want to ignore all google subdomains in any top level domain:  
.google.

Also, if you send your prefered URL to the script as a parameter, it will bypass all the prompts and automatically install/update the Unified Hosts in the local hosts file. This is useful for things like scheduling a task to update your Unified Hosts daily or weekly, etc. You can even update yourt hosts randomly throughout the day at certain times to switch between Unified Hosts to, for example, only allow social in the evenings or on the weekends. If you do decide to make a scheduled task, also remember the account issuing the task must still have administrative privileges to be able to write to the local hosts file.

Because no backup of your local hosts file is needed, entries in the Unified Hosts relating to the localhost and other loopback addresses have been removed to prevent possible conflict with preexisting entries. No backup is needed because this script implements the Unified Hosts within opening and closing tags to clearly segment it from the user's preexisting entries and allow the script to know what area of the file to overwrite during an update or remove during removal.

**This script is in active development, so please share your feedback on what you like and don't like so we know what direction to take and don't inadvertently make things worse**
