
param(
    [Parameter(Mandatory)]$csvfilename,
    [string]$user,
    [string]$password,
    [string]$continue
    )

$scriptpath = "C:\AD_Operation\New_User_Creation\"

#----------------------------Global Variables
$LogFile = $scriptpath + "Logs\$($domain.Name)_ADUserAccount_Creation_Logs-$(((get-date).ToUniversalTime()).ToString("MMddyyyyThhmmssZ")).txt"
Start-Transcript -Path $LogFile
$var = Get-Content $($scriptpath +"var.json") | ConvertFrom-Json
# change the blow values while reusing the script
$resourcegroup = $var.ResourceGroupName
$storageaccount= $var.Storageaccount
$container = $var.ContainerName
$TenantId = $var.TenantID
$subscription = $var.Subscription
$KeyName = $var.KeyName
$userid = $var.UserID
$appkey = $var.Azureappkeyencrypted
$copytopath = $scriptpath
#----------------------------encrypted password
#$Password = ConvertTo-SecureString $appkey -AsPlainText -Force
$Password = ConvertTo-SecureString $appkey
$myPsCred = New-Object System.Management.Automation.PSCredential ($userid,$Password)

#Make the connection to Azure Account 
Connect-AzAccount -ServicePrincipal -Credential $myPsCred -TenantId $TenantId -Subscription $subscription
Write-Output "The $KeyName key is used here to athentication"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#----------------------------Arguments and 
<#
$csvfilename = $args[0] #csv filename should be with extention .csc
#Admin User credentials
$user = $args[1]
$password = $args[2]
$continue = $args[3] #to create users from Run command  
#>
#----------------------------function 1 to copy CSV file from Azure Local System
#function 1 for copy file locally

function Get-CSVfile {
    $ErrorActionPreference = "Stop"
    Write-Output "Provided file name is: $csvfilename"
    try {
        
        # what is context???? to set the subscription to work with
        $context = (Get-AzStorageAccount -Name $storageaccount -ResourceGroupName $resourcegroup).context

        #to download the file from blob to server
        Get-AzStorageBlobContent -container $container -blob $csvfilename -Destination $copytopath -context $context

        
        }catch {
            Write-Error $_
            #break
            
            }
    

}
#----------------------------function 2 to Show the CSV file and Create Users
function Import-CreateUser {
    $ErrorActionPreference = "Continue"

    Write-Output " "
    

    $ADUsers = Import-Csv -Path $($copytopath+ $csvfilename) #+ ".csv"
    $ADUsers | Format-Table
    #Write-Output "`nCheck if all the data is correct above`n"

    #Remove the file from system
    Remove-Item $($copytopath + $csvfilename)

    if ($continue -eq 'yes'){

        Write-Output "Proceeding to create the users"
    }else{
        $continue = Read-Host "Enter [y/Y] to continue"
        if ($continue -eq 'y'){
            Write-Output "Proceeding to create the users"
        }else{
            Write-Output "Entered value is not [y/Y]"
            break
    }
    }

    if ($user -and $password){
        
        Write-Output "`nUsing $user credentials to create user"
        $Secure_password = ConvertTo-SecureString $password -AsPlainText -Force
    }else{
        Write-output "Enter the Admin User Credentials for the operation`n"
        $user = Read-Host "Enter Admin-Username"
        $Secure_password = Read-Host "Enter Password" -AsSecureString
        Write-Output "`nUsing $user credentials to create user"
        Write-Output " "
    }


    $credentials = New-Object -typename System.Management.Automation.PSCredential $user, $Secure_password
    Import-Module ActiveDirectory
    $domain_name = Get-ADDomain | select -Property dnsroot

    foreach ($User in $ADUsers)
    {
	    #Read user data from each field in each row and assign the data to a variable as below
		
	    $Username = $User.username
	    #$OU = $User.ou #This field refers to the OU the user account is to be created in
        $description = $User.description
	    $email = $User.email
        $Password = $User.password
	    $AdGroup = $User.memberof
        $AdGroup1 = $User.memberof1
        $AdGroup2 = $User.memberof2
        $upn = $Username +'@'+ $domain_name.dnsroot

	    #Check to see if the user already exists in AD
	    if (Get-ADUser -F {SamAccountName -eq $Username} -Credential $credentials)
	    {
		     #If user does exist, give a warning
		     Write-Warning "A user account with username $Username already exist in $($domain.NetBIOSName) Active Directory Domain."
	    }
	    else
	    {
		    #User does not exist then proceed to create the new user account
		
            #Account will be created in the OU provided by the $OU variable read from the CSV file
	    New-ADUser `
                -SamAccountName $Username `
                -UserPrincipalName $upn `
                -Name $Username `
                -GivenName $Username `
                -Enabled $True `
                -DisplayName $Username `
                -Description $description `
	            -EmailAddress $email `
                -AccountPassword (convertto-securestring $Password -AsPlainText -Force) `
                -Verbose
	        
                If ($AdGroup) 
                { 
                    Add-ADGroupMember "$AdGroup" $Username -Verbose 
                } 
           
                If ($AdGroup1) 
                { 
                    Add-ADGroupMember "$AdGroup1" $Username -Verbose 
                } 
            
                If ($AdGroup2) 
                { 
                    Add-ADGroupMember "$AdGroup2" $Username -Verbose 
                } 

	    Write-Host "$($domain.NetBIOSName) domain user account for $Username has been created on $(Get-Date) and added it into $AdGroup $AdGroup1 $AdGroup2 AD Groups"
        $getuser = Get-ADUser -Identity $Username
        #set-adobject $getuser.DistinguishedName -protectedFromAccidentalDeletion $true -Verbose
        }
    }


    
}


#----------------------------Main Script

Get-CSVfile
Import-CreateUser
    
#--------------------------
Stop-Transcript