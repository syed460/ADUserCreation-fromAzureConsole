# Create New Users from Azure Portal on the AD server

Using:
    Azure VM-Serial console

Using Powershell Script which we keep inside the server.

## Variables are stored in the var.json file

    $storageaccount= $var.storageaccount
    $container = $var.ContainerName
    $TenantId = $var.TenantID
    $subscription = $var.Subscription
    $KeyName = $var.KeyName
    $userid = $var.UserID


Here we are using the encrypted key value:
    $appkey = $var.Azureappkeyencrypted

-----------------------------------
Steps to perform the user creation:

Step 1:
	Create CSV File with the user details as below,
    username,discription,email,password,memberof1,memberof2,memberof3

    Example: -

    ![csvfilepic](https://github.com/syed460/ADUserCreation-fromAzureConsole/blob/main/csvfilepic.png "csvfile")
    

Step 2:
	Upload the file into azure storage account > under the container
	
	Storeage Account: <your account>
	Container: <new-user-creation>

Step 3:
	Navigate to VM > Serial console 
	

Step 4:
	Provide the Absolute patch of the script with the four arguments.
	
    1. file.csv (csv file name with its extention)
    2. YourUsername (for AD authentication)
    3. YourPassword (for AD authentication)
    4. yes (to proceed to user creation as confirmation)

	C:\<path>\main.ps1 -csvfilename file.csv -user YourUsername -password YourPassword -continue yes

Step 5:
    Take Screenshot of the output for artifacts

-------------------
