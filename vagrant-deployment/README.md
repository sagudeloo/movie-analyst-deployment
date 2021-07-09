# movie-analyst-deployment

Configuration to deploy and provision movie analyst application.  
`Vagrantfile` set up 3 Ubuntu-20.04 machines with 1 Core and 1024MiB of RAM for UI, API and Database.  
`node-provisioner.sh` is the file to do the provision the UI and API machines.  
`db-provisioner.sh` is the file to do the provision db machine.  
`db-provisioner.sh` file to migrate the database model from `movie_analyst-api` repository 
`data` directory this will used to store any kind of data that is needed in the provision process
