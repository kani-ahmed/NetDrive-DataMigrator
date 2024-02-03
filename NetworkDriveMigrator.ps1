<#
This script is designed to be run on a Windows computer to remove the D: drive and extend the C: drive to take up the unallocated space.
Before it does that, it checks if the D: drive exists and is in the correct partition, and if the C: drive exists and is in the correct partition.
It also checks if the D: drive has enough free space to move all files to the C: drive before removing the D: drive.
If the D: drive does not exist or is not in the correct partition, or if the C: drive does not exist or is not in the correct partition, the script will stop.
If the D: drive does not have enough free space to move all files to the C: drive, the script will stop.
If the D: drive exists and is in the correct partition, and if the C: drive exists and is in the correct partition, and if the D: drive has enough free space to move all files to the C: drive, the script will move all files from the D: drive to the C: drive before removing the D: drive.
Then it will extend the C: drive to take up the rest of the unallocated space and move on to the next computer.
 #>



<#-------------------------------------------------------------------------------------------------------------------------------------#
           This part of the code establishes a connection with the Flask, so all logging data is submitted to us in real time
#-------------------------------------------------------------------------------------------------------------------------------------#>

# Define a function for logging
# This function will post the log message to the Flask log endpoint and also write the log message to a local log file
# The local log file will be located at C:\Windows\Temp\nuked.log
# The log message will be posted to the Flask log endpoint at http://your-flask-server-ip:5000/log (change this to the correct URI of your Flask log endpoint)
# The API endpoints are secured with a firebase token, so only authorized users can see the logs in real time
function Log-Event {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    $logUri = "http://your-ip-address:your-port-number/log" # Change this to the correct URI of your Flask log endpoint
    $logFile = "C:\Windows\Temp\nuked.log" # Path to your local log file (change this to the correct path of your local log file)

    # Post the log message to your Flask log endpoint
    Invoke-RestMethod -Method POST -Uri $logUri -Body (ConvertTo-Json -InputObject @{ "message" = $Message }) -ContentType "application/json"

    # Also write the log message to the local log file
    $logMessage = "[{0}] - {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message # Format the log message with the current date and time
    Add-Content -Path $logFile -Value $logMessage # Write the log message to the local log file
}


# Start of the script

Log-Event -Message "==========================================================================================================================="
$computerName = hostname
$ipResult = Test-Connection -ComputerName $computerName -Count 1

if ($ipResult) {
    $ipAddress = $ipResult.Address.IPAddressToString
    $hostName = [System.Net.Dns]::GetHostEntry($ipAddress).HostName
} else {
    Log-Event -Message "Failed to retrieve IP address for computer: $computerName"
}

Log-Event -Message "==========================================================================================================================="

# Log information about the current computer
Log-Event -Message "Scanning computer name: $computerName      Host Name: $hostName     IP address: $ipAddress"
Log-Event -Message "==========================================================================================================================="
Log-Event -Message "Script started."


# Define the source and destination directories
$source = "D:\"
$destination = "C:\Temporary Data\"

# Check if the destination folder exists and create it if it doesn't
if (!(Test-Path -Path $destination)) {
    New-Item -ItemType Directory -Path $destination -Force
    # Set the hidden attribute for the destination folder
    $hiddenAttribute = [System.IO.FileAttributes]::Hidden
    Set-ItemProperty -Path $destination -Name Attributes -Value $hiddenAttribute
}

# Check if C: and D: exist and are in the correct partitions
#---------------------------------------------------------------------------------------------------------------------------------------

# select disk 0, this will be the only disk we will be working with
$disk0 = Get-Disk -Number 0

# display current partition map
$allPartitions = $disk0 | Get-Partition # Get all partitions on disk 0
$partitionInfo = $allPartitions | Format-Table | Out-String # Format the partition information as a table
Log-Event -Message $partitionInfo # Log the partition information

# checking if disk 0, parition 4 is the C drive [basically if C drive exists [it should in this case unless...????], and in this correct partition], otherwise returns null
$partitionC = $disk0 | Get-Partition | Where-Object { $_.DriveLetter -eq 'C' -and $_.PartitionNumber -eq 4 }

# checking if disk 0, partition 6 or 5 is the D drive [basically if D drive exists and in this correct partition], otherwise returns null
$partitionD = $disk0 | Get-Partition | Where-Object { $_.DriveLetter -eq 'D' -and ($_.PartitionNumber -eq 6 -or $_.PartitionNumber -eq 5) }


# this is where we verify if variables $partitionC and $partitionD hold null or drives exist
if ($null -eq $partitionC) {
    Log-Event -Message "C: does not exist or is not in Disk 0 Partition 4."
    return
}
Log-Event -Message "C: exists and is in Disk 0 Partition 4."

#if we encounter null, we basically return: meaning we stop the script and proceed to the next computer
if ($null -eq $partitionD) {
    Log-Event -Message "D: does not exist or is not in Disk 0 Partition 6."
    return
}
Log-Event -Message "D: exists and is in Disk 0 Partition 6 or 5."



<#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
            Now that the basic drive and parition checking is done, if our script gets to this stage, it means:

                1) C: exists and is in Disk 0 Partition 4.
                2) D: exists and is in Disk 0 Partition 6.

            We can now proceed with moving the files from D to C:\Temporary Data, if:

                1) The total file size of all files in D drive excluding .msi and .exe files < total free space in C drive
                otherwise, return and stop executing, proceed to the next computer
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------#>

<#Performing cleanup on ccmcache folder before moving files#>

<#

$ccmCachePath = "C:\Windows\ccmcache"

$items = Get-ChildItem -Path $ccmCachePath -File -Recurse

# Process items in reverse order to ensure files are deleted before folders
foreach ($item in $items | Sort-Object -Property FullName -Descending) {
    $path = $item.FullName
    $isPersistent = (Get-Item -Path $path).Attributes -band [System.IO.FileAttributes]::Hidden

    if (-not $isPersistent) {
        # Delete non-persistent item
        Write-Host "Deleting non-persistent item: $path"
        Remove-Item -Path $path -Force
    } else {
        # Skip persistent item
        Write-Host "Skipping persistent item: $path"
    }
}

# Delete empty folders inside ccmcache
$emptyFolders = Get-ChildItem -Path $ccmCachePath -Directory -Recurse | Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -File -Force) }

foreach ($folder in $emptyFolders | Sort-Object -Property FullName -Descending) {
    $path = $folder.FullName

    # Delete empty folder
    Write-Host "Deleting empty folder: $path"
    Remove-Item -Path $path -Force -Recurse
}

#>



# Get the number of files in the source drive and total size excluding .exe and .msi files
$sourceFiles = Get-ChildItem -Path $source -Recurse -File | Where-Object { $_.Extension -ne ".exe" -and $_.Extension -ne ".msi" }

# Check the count of files [this is already excluding .msi and .exe files]
$fileCount = $sourceFiles.Count

# Get the total size of the files and send it back for real time viewing 
$totalFileSize = ($sourceFiles | Measure-Object -Property Length -Sum).Sum / 1GB # Size in GB
Log-Event -Message "There are $fileCount files in the source drive, with a total size of $totalFileSize GB excluding .exe and .msi files."

# Check if destination partition has enough free space
$destinationDrive = $partitionC | Get-Volume # Get the volume information of the destination partition
$freeSpace = ($destinationDrive.SizeRemaining / 1GB) # Free space in GB of the destination partition [C drive]

# If C drive cannot contain all moved files, do not move anything, return, and move to the next computer
if ($freeSpace -lt $totalFileSize) {
    Log-Event -Message "Not enough free space in the destination partition. Required: $totalFileSize GB, available: $freeSpace GB."
    return
}

<#------------------------------------------------------------------------------------------------------------------------------------------------------------#
            1) If the script reaches here, it means, all requirements checked, and we have enough space to move all files.
            2) We are mirroring the folder structure of files in D drive of all user computers. Therefore, if file X was under Folder Y in D drive, 
            when moved to C, we keep the same folder structure [File and Folder names]
#------------------------------------------------------------------------------------------------------------------------------------------------------------#>



Log-Event -Message "Sufficient free space in the destination partition. Required: $totalFileSize GB, available: $freeSpace GB."

# Move all the files that are not .exe or .msi from D: to C:\Temporary Data [variable $sourceFiles contains already filtered file types]

#If there are no files in D drive, the following loop will not execute, meaning we will just proceed to the next code and delete the D drive
#If one of the files is open, abort mission

try {
    # Move the files from D: to C:\Temporary Data [variable $sourceFiles contains already filtered file types]
    $sourceFiles | ForEach-Object {
        # Get the relative path of the file from the source directory
        $relativePath = $_.FullName.Substring($source.length)
        # Get the destination path of the file in the destination directory [C:\Temporary Data]
        $dest = Join-Path -Path $destination -ChildPath $relativePath
        # Create the destination directory if it does not exist [this is to maintain the folder structure of the files]
        $destDir = Split-Path -Path $dest -Parent
        if (!(Test-Path $destDir)) {
            # Create the destination directory if it does not exist
            New-Item -ItemType Directory -Path $destDir -Force
        }
        # Move the file to the destination directory [C:\Temporary Data]
        Move-Item -Path $_.FullName -Destination $dest -Force
        # Log the successful move of the file to the destination directory [C:\Temporary Data]
        Log-Event -Message "Moved file $($_.FullName) to $dest."
    }
}
catch {
    #abort mission if one of the files is open
    $openFileName = $_.Exception.TargetObject.Name # Get the name of the file that is open and causing the error to be thrown [if any]
    Log-Event -Message "File $openFileName is open. Aborting mission." # Log the error message
	exit # Stop the script
}

<#----------------------------------------------------------------------------------------------------------------------------------#
            Final Clean Up:
                1) It is needed, but as a security and safety check, we check if partition D exists again
                2) Delete parition D
#----------------------------------------------------------------------------------------------------------------------------------#>

# Check if partition D exists and is on Disk 0 Partition 6
$disk0 = Get-Disk -Number 0 # Get disk 0 information again
# Check if partition D exists and is on Disk 0 Partition 6 or 5 [we already checked this, but we are doing it again for safety]
$partitionD = $disk0 | Get-Partition | Where-Object { $_.DriveLetter -eq 'D' -and ($_.PartitionNumber -eq 6 -or $_.PartitionNumber -eq 5) }
# If partition D does not exist or is not in Disk 0 Partition 6, log the error and stop the script [this is just a safety check]
if ($null -eq $partitionD) {
    Log-Event -Message "Final Parition D check: Partition D does not exist or is not in Disk 0 Partition 6."
    return
}
# If partition D exists and is in Disk 0 Partition 6, log the success message
Log-Event -Message "Final Parition D check: Partition D exists and is in Disk 0 Partition 6."

# Delete partition D
try {
    $partitionD | Remove-Partition -Confirm:$false
    Log-Event -Message "Partition D deleted."
}
catch {
    #if D cannot be deleted, report back, stop the script
    Log-Event -Message "Partition could not be D deleted."
}




<#---------------------------------------------------------------------------------------------------------------------------------#
            Final clean up cont:

            3) Check if the recovery parition in disk 0 parition number 5 exists:
                            3.1) if it is does, delete it. Then extend C drive to take up the rest of the unallocated space
                            3.2) if it does not, then just then extend C drive to take up the rest of the unallocated space
#---------------------------------------------------------------------------------------------------------------------------------#>


# Check if recovery partition exists
$recoveryPartition = $disk0 | Get-Partition | Where-Object { $_.PartitionNumber -eq 5 }
if ($null -ne $recoveryPartition) {
    # Delete the recovery partition
    $recoveryPartition | Remove-Partition -Confirm:$false
    Log-Event -Message "Recovery partition on Disk 0 Partition 5 deleted."
}

# Extend partition C
$maxSize = Get-PartitionSupportedSize -DriveLetter C # Get the maximum size that the partition can be extended to
Resize-Partition -DriveLetter C -Size $maxSize.SizeMax # Extend the partition to the maximum size
Log-Event -Message "Partition C extended." # Log the successful extension of partition C

# Get the updated drives information
$allPartitions = $disk0 | Get-Partition # Get all partitions on disk 0
$partitionInfo = $allPartitions | Format-Table | Out-String # Format the partition information as a table
Log-Event -Message $partitionInfo # Log the updated partition information



# End of the script
Log-Event -Message "Script ended." # Log that the script has ended


