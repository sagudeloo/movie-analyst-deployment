# movie-analyst-deployment

Configuration to deploy and provision movie analyst application.  
`Vagrantfile` set up 3 Ubuntu-20.04 machines with 1 Core and 1024MiB of RAM for UI, API and Database.  
`node-provisioner.sh` is the file to do the provision the UI and API machines.  
`db-provisioner.sh` if the file to do the provision db machine.  
`data` directory this will used to store any kind of data that is needed in the provision process
