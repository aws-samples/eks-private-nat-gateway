### Instructions for initializing the Aurora PostgreSQL database instance 
First, laumch an EC2 instance in the same VPC as the Aurora/RDS PostgreSQL database. Copy the following files over to that instance from your local environment using a CLI utility such as 'scp'
- exports
- init-1.sh
- init-2.sh
- postgres-data.csv

Then, run the commands manually one by one.

<br/>

Install 'psql' tool on the instance using the following command.
```
sudo amazon-linux-extras install postgresql10 -y
```


Export the environmane variables in the **exports** file. Make sure to set a password with the variabe **DBPASSWORD** and also update the value of variable **DBHOST** to the endpoint URL of the Aurora PostgreSQL database.
```
source exports
```

Now, run the DDL and DML commands in the scripts **init-1.sh** and **init-2.sh**. This will setup the relevant database, schema, tables in the Aurora PostgreSQL database, instance.
```
init-1.sh  # When prompted for password, enter 'postgres'
init-2.sh  # When prompted for password, enter the password used for DBPASSWORD variable
```

Now, import data into Postgres database. First login into the remote Aurora PostgreSQL instance using the **psql** utility you installed earlier. Then, run the **\copy** command from within the Postgres shell. If necessary, modify the path name of the CSV file you are using for the import
```
psql --host=$DBHOST --user=$DBROLE --dbname=$DBNAME
\copy analytics.popularity_bucket_permanent from 'postgres-data.csv' WITH DELIMITER ',' CSV HEADER;
```
