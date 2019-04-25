function ResetUserPasswords($usersFile)
{
  $file = Get-Content $usersFile
  $line = $null

  if($file.Length -gt 0)
  {
    Write-Output ""
    Write-Output ""
    Write-Output "User(s) failed the audit. Their password will be reset to 'Football1'."
    Write-Output "They will be required to change their passwords next time they login."
    Write-Output "More importantly, they will need to be taught how to choose a stronger password."
    Write-Output ""
    Write-Output ""
    Write-Output "Starting the rest process now..."

    # Loop through the file with usernames and reset their passwords
    # I'm purposely giving them a weak password for demonstration purposes (so I can keep re-running the script)
    
    foreach ($line in $file)
    {     
      Write-Output "    Resetting password for: $($line)"

      $UserName = $null
      $Password = ConvertTo-SecureString -String "Football1" -AsPlainText –Force
            
      # Split the username from the domain (e.g. "jd.net\jwilson" should return just "jwilson")
      $line = $line -split ("\\")
      $UserName = $line[1] 

      Set-ADAccountPassword -Identity $UserName -NewPassword $Password –Reset -PassThru | Set-ADuser -ChangePasswordAtLogon $True            
    }

    Write-Output "Passwords have been reset!"
  }
}



##################################################################################################################
#
# This directory will be wherever you have installed John the Ripper and NtdsAudit
# If those are not installed in this directory, or if the script is not in this directory, it will not work
#
##################################################################################################################
#
# Just in case, return to the right directory
cd C:\Users\Administrator\Documents\PasswordAuditTools

# Create a new directory each time this runs. Store the working files and results here
$NewDirectory = "C:\PasswordAudit_$(get-date -f yyyy-MM-dd_hh_mm_ss)"

# Get the ntds.dit and SYSTEM files. Place them in $NewDirectory
ntdsutil "ac i ntds" "ifm" "create full $($NewDirectory)" quit quit

# Use ntds.dit and SYSTEM to extract the user info and passwords
.\NtdsAudit "$($NewDirectory)\Active Directory\ntds.dit" "-s" "$($NewDirectory)\registry\SYSTEM" "-p" "$($NewDirectory)\PasswordDump.txt" "--users-csv" "$($NewDirectory)\users.csv"

# John the Ripper results (staging file
$resultsFile = New-Item -Path "$($NewDirectory)\results.txt"

# Strip the $resultsFile and only show the users who failed (without the passwords or other extra info)
$usersFile = New-Item -Path "$($NewDirectory)\users.txt"

# Move to where John the Ripper is installed (TODO: check if this exists in script. If not, install it or instruct users to)
cd C:\Users\Administrator\Documents\PasswordAuditTools\john180j1w\john180j1w\run

# --show is the "quick" or basic scan. TODO: Ask for user input to see if they want to do a basic scan or a full one.
# If they want to do a full one, warn them of the performance impact and ask for a time limit in minutes (or just let it rip)
.\john.exe "--format=nt" "$($NewDirectory)\PasswordDump.txt" "--show" | Out-File $resultsFile

$file = Get-Content $resultsFile

$line = $null

if($file.Length -gt 0)
{
  Write-Output "The following users failed the audit..."

  foreach ($line in $file)
  {
    # John the Ripper adds a couple of lines to tell the user what happened. We don't need to add those lines to the output file
    if($line -ne "" -and $line -notlike "*password hashes cracked*")
    {
      $UserName = $null
      $Password = $null

      # Each row is colon separated. The first value will be the doman/username (e.g. "jd.net\jwilson"). We don't want/need the rest of the row
      $line = $line -split (":")
      $UserName = $line[0]

      Write-Output "$($UserName)" 

      # Add the user to the usersFile. This file will allow us to reset the passwords more easily.
      Write-Output "$($UserName)" | Out-File $usersFile -Append
    }
  }

  # Clean up any files with sensitive data. Only leave the file with usernames intact.
  # Adding this here so the files go away before the script hangs and waits for a response
  # The next step literally asks them to go to that directory and open files.
  # This should also help clarify which file they need to review (They don't try to open users.csv instead of users.txt)
  Remove-Item $resultsFile, "$($NewDirectory)\PasswordDump.txt", "$($NewDirectory)\users.csv"
  
  Write-Output ""
  Write-Output ""
  Write-Output "You can review the users and add/remove any from this file before continuing: $($usersFile)"
  $Response = Read-Host "Would you like to reset their passwords now? (Y/N)"

  # Check for "Y", "N", or an invalid response (ask again if it's an invalid response)
  while($Response.ToUpper() -ne "Y")
  {
    if($Response.ToUpper() -eq "N")
    {
      Write-Output "Passwords will not be reset. Please review the user accounts in your free time..."
      exit
    }
    Write-Output "Invalid response..."
    Write-Output ""
    $Response = Read-Host "Would you like to reset their passwords now? (Y/N)"
  }

  ResetUserPasswords($usersFile)
}
