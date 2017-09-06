##Author : Paranoid Ninja
##Email  : paranoidninja@protonmail.com
##Desc   : Simple Powershell Script to deploy Sysmon via winrm. Change the shared folder path in SourceFolder and add all computer names in the CompName Variable text file/path

$SourceFolder = "\\VBOXSVR\shared_box\Sysmon_testing\"
$CompName = Get-Content "C:\Users\Administrator\Desktop\machine.txt"

foreach ($computer in $CompName)
{
    $DestinationFolder = "\\$CompName\C$\sysmon"

    if(!(Test-Path -path $DestinationFolder))
    {
        New-Item $DestinationFolder -Type Directory
    }

    robocopy $SourceFolder $DestinationFolder
    Invoke-Command -ComputerName $computer -ScriptBlock { & cmd /c "C:\Sysmon_testing\Sysmon64.exe -i C:\Sysmon_testing\sysmon_config.xml -accepteula"}

    #Use the below command to uninstall the service in all the computers

    #Invoke-Command -ComputerName $computer -ScriptBlock { & cmd /c "C:\sysmon\Sysmon64.exe -u"}
}
