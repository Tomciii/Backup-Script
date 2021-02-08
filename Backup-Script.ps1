<#  
    .Description
    This function creates backups of a folder, logs changes,
    and creates a .zip file of the newest backup folder.

    .Parameter [string]$folder
    The folder that will be archived.
#>

function backup([string]$folder)
{
    try
    {
       <#
       The source path that leads to the folder we want to archive.
       $source might need to be changed depending on where we want to copy from.
       #>
        $source = "C:\Users\Tomcii\Desktop\" + $folder

        #Throw exception if $folder doesnt exist
         $test = Test-Path $source
        if ($test -eq $false)
            {
            Throw "$folder doesnt exist"
            }

        #Creates a new folder to store all the archived files.
        $backupFolder = "C:\Backups\"
         $test = Test-Path $backupFolder
        if ($test -eq $false)
            {
            mkdir $backupFolder
            }

            cd $backupFolder
        #Create a Hash-Files folder
        $hashFolder = "C:\Backups\hash"
        $test = Test-Path $hashFolder
        if ($test -eq $false)
            {
            mkdir $hashFolder
            }

        #The destination path will be the name of the archived folder.
        $destination = $backupFolder + $folder

        #Items to delete from the backup.
        #Enter the file names into the array (e.g. "file.txt")
        $itemsToDelete = @()

        #The parameter for how many times the folder will be stored.
        #ZIP file will always be the most current.
        [int]$backupCount = 3

        #Integer used later for the log file.
        [int]$amountOfItemsInDest

        #The creation of the backup-folder.
        for ($i=1; $i -le $backupCount; $i++)
        {
        #Checks if a backup-folder already exists.
         $test = Test-Path $destination$i
            if ($test -eq $false)
            {
            #Copies the folder
            Copy-Item -Path $source -Destination $destination$i -Recurse -Force

            #Removes Items we dont want
            if ($itemsToDelete -ne 0)
            {
                for ($j=0; $j -le $itemsToDelete.Count; $j++)
                    {
                      Get-ChildItem -File -Path $destination$i\* -include $itemsToDelete[$j] -Filter $itemsToDelete[$j] -Recurse | 
                      Remove-Item -Force -Verbose
                    }   
                }

                #Hash-Compare Setup. Creating .txt files for this step.
                $hashS = "c:\backups\hash\hashofS.txt"
                $hashD = "c:\backups\hash\hashofD.txt"

                Get-ChildItem $source -Recurse -File | Get-FileHash -Algorithm MD5 | Select -ExpandProperty Hash > $hashS
                Get-ChildItem $destination$i -Recurse -File | Get-FileHash -Algorithm MD5 | Select -ExpandProperty Hash > $hashD

                $S = Get-Content $hashS
                $D = Get-Content $hashD

               #Info used for the log file.
                if(Compare-Object $S $D)
                {
                echo "Folders are different" >> "Log.txt"
                }
                else
                {
                echo "Folders are the same." >> "Log.txt"
                }
                $amountOfItemsInDest = ((dir $destination$i -Recurse | Measure-Object).Count - $itemsToDelete.Count)


            #Creates a .ZIP file out of the most current folder backup.
            Compress-Archive -Path $destination$i -Destination $destination -Force

            #Breaks out of the loop if it created a zip file.
            break;
            }
            else 
            {
           
            if ($i -eq $backupCount)
                {
                 #If the maximum amount of backup folders exist, the newest one gets overwritten.
                 #A lot of the same code here, main difference the next 2 lines. (To be able to work with $i)
                Remove-Item $destination$i -Force -Recurse
                Copy-Item -Path $source -Destination $destination$i -Recurse -Force

                #Removes Items we dont want
                if ($itemsToDelete -ne 0)
                {
                    for ($j=0; $j -le $itemsToDelete.Count; $j++)
                    {
                      Get-ChildItem -File -Path $destination$i\* -include $itemsToDelete[$j] -Filter $itemsToDelete[$j] -Recurse | 
                      Remove-Item -Force -Verbose
                    }
                }

                #Hash-Compare Setup. Creating .txt files for this step.
                $hashS = "c:\backups\hash\hashofS.txt"
                $hashD = "c:\backups\hash\hashofD.txt"

                Get-ChildItem $source -Recurse -File | Get-FileHash -Algorithm MD5 | Select -ExpandProperty Hash > $hashS
                Get-ChildItem $destination$i -Recurse -File | Get-FileHash -Algorithm MD5 | Select -ExpandProperty Hash > $hashD

                $S = Get-Content $hashS
                $D = Get-Content $hashD

                #Info used for the log file.
                if(Compare-Object $S $D)
                {
                echo "Folders are different" >> "Log.txt"
                }
                else
                {
                echo "Folders are the same." >> "Log.txt"
                }
                $amountOfItemsInDest = ((dir $destination$i -Recurse | Measure-Object).Count - $itemsToDelete.Count)

                #Creates a .ZIP file out of the most current folder backup.
                Compress-Archive -Path $destination$i -Destination $destination -Force
                }
            }
        }

        #Deleting the temp hash files.
        remove-item $hashFolder -Recurse -Force

        #Creating the log file.
        $getDate = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
        $amountOfItems = ((dir $source -Recurse | Measure-Object).Count)

        echo $getDate >> "Log.txt" 
        echo "Added New Backup Folder of: $folder" >> "Log.txt"
        echo "Amount of items in original $folder : $amountOfItems" >> "Log.txt"
        echo "Amount of items in backup $folder : $amountOfItemsInDest" >> "Log.txt"

      if ($itemsToDelete -ne 0)
        {
        echo "Items deleted from this folder:" >> "Log.txt"
        }
        
         for ($j=0; $j -le $itemsToDelete.Count; $j++)
                {
                   echo $itemsToDelete[$j] >> "Log.txt"
                }

        echo "" >> "Log.txt"
    }
    catch
    {
    Write-Host $Error[0]
    }
}