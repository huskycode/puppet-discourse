Discourse Puppet File
=====================

A puppet script to install Discourse (discourse.org) based on 
the instruction provided at the [official documentation](https://github.com/discourse/discourse/blob/master/docs/INSTALL-ubuntu.md)

This is tested on ubuntu 12.04 x64

Todo
----
I aim to provide a single click solution to
install discourse on a blank ubuntu machine.

This is not fully working. Yet. The server starts, but not automatically. Still need to complete a few steps. 

* Need to add a script for bluepill. I am deciding whether we should use upstart instead.
* Clean up the Execs to be idempotent
* Make hostname a template variable
* Have an instruction on how to configure a secure password

How to use
----------
    ## Step 1 -- This will install puppet and librarian-puppet. Should be called only once.
    ./bootstrap.sh
    
    ## Step 2 -- Use puppet to install discourse. Run this as often as you like.
    ./run.sh


