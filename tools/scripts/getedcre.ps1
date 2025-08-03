function convertFileSize {
    param(
        $bytes
    )

    if ($bytes -lt 1MB) {
        return "$([Math]::Round($bytes / 1KB, 2)) KB"
    }
    elseif ($bytes -lt 1GB) {
        return "$([Math]::Round($bytes / 1MB, 2)) MB"
    }
    elseif ($bytes -lt 1TB) {
        return "$([Math]::Round($bytes / 1GB, 2)) GB"
    }
}

function DownloadFile($url, $targetFile)
{
    #Load in the WebClient object.
    try {
        $Downloader = New-Object -TypeName System.Net.WebClient
    }
    catch [Exception] {
        Write-Error $_ -ErrorAction Stop
    }

    try {

        #Start the download by using WebClient.DownloadFileTaskAsync, since this lets us show progress on screen.
        $FileDownload = $Downloader.DownloadFileTaskAsync($Url, $targetFile)

        #Register the event from WebClient.DownloadProgressChanged to monitor download progress.
        Register-ObjectEvent -InputObject $Downloader -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged | Out-Null

        #Wait three seconds for the registration to fully complete
        Start-Sleep -Seconds 3

        if ($FileDownload.IsFaulted) {
            Write-Verbose "An error occurred. Generating error."
            Write-Error $FileDownload.GetAwaiter().GetResult()
            break
        }

        #While the download is showing as not complete, we keep looping to get event data.
        while (!($FileDownload.IsCompleted)) {

            if ($FileDownload.IsFaulted) {
                Write-Error $FileDownload.GetAwaiter().GetResult()
                break
            }

            $EventData = Get-Event -SourceIdentifier WebClient.DownloadProgressChanged | Select-Object -ExpandProperty "SourceEventArgs" -Last 1

            $ReceivedData = ($EventData | Select-Object -ExpandProperty "BytesReceived")
            $TotalToReceive = ($EventData | Select-Object -ExpandProperty "TotalBytesToReceive")
            $TotalPercent = $EventData | Select-Object -ExpandProperty "ProgressPercentage"

            Write-Progress "Downloading File" -Id 2 -Status "Percent Complete: $($TotalPercent)%" -CurrentOperation "Downloaded $(convertFileSize -bytes $ReceivedData) / $(convertFileSize -bytes $TotalToReceive)" -PercentComplete $TotalPercent
        }
    }
    catch [Exception] {
        $ErrorDetails = $_

        switch ($ErrorDetails.FullyQualifiedErrorId) {
            "ArgumentNullException" { 
                Write-Error -Exception "ArgumentNullException" -ErrorId "ArgumentNullException" -Message "Either the Url or Path is null." -Category InvalidArgument -TargetObject $Downloader -ErrorAction Stop
            }
            "WebException" {
                Write-Error -Exception "WebException" -ErrorId "WebException" -Message "An error occurred while downloading the resource." -Category OperationTimeout -TargetObject $Downloader -ErrorAction Stop
            }
            "InvalidOperationException" {
                Write-Error -Exception "InvalidOperationException" -ErrorId "InvalidOperationException" -Message "The file at ""$($Path)"" is in use by another process." -Category WriteError -TargetObject $Path -ErrorAction Stop
            }
            Default {
                Write-Error $ErrorDetails -ErrorAction Stop
            }
        }
    }
    finally {
        #Cleanup tasks
        Write-Progress "Downloading File" -Id 2 -Completed
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged

        if (($FileDownload.IsCompleted) -and ($FileDownload.IsFaulted)) {
            #If the download was terminated, we remove the file.
            $Downloader.CancelAsync()
            Remove-Item -Path $targetFile -Force
        }

        $Downloader.Dispose()
    }
}

# Detect architecture
if ([System.Environment]::Is64BitOperatingSystem) {
    $file = "edcre-v1.1.0-windows-x86_64-static.zip"
} else {
    $file = "edcre-v1.1.0-windows-i686-static.zip"
}

$folderPath = "./tools/bin/win/edcre"

# Ensure parent directories exist
$parentPath = Split-Path -Parent $folderPath
if (-not (Test-Path -Path $parentPath)) {
    New-Item -Path $parentPath -ItemType Directory -Force
}

if (-not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory -Force
}
else {
    $directoryInfo = Get-ChildItem $folderPath | Measure-Object

    if ($directoryInfo.count -ne 0)
    {
        write-host "EDCRE directory is not empty! Proceeding will clear all of its contents."
        $confirmation = Read-Host "Are you Sure You Want To Proceed (y/n)"

        if ($confirmation -eq 'y') 
        {
            write-host "Clearing EDCRE directory"
            Remove-Item "$($folderPath)/*" -Recurse -Force
        }
        else
        {
            Break
        }
    }
}

Write-Progress "Installing EDCRE" -Id 3 -status "Step 1/3: Downloading EDCRE..." -PercentComplete 0

DownloadFile "https://github.com/alex-free/edcre/releases/download/v1.1.0/$($file)" "$($folderPath)/$($file)"

if ([System.IO.File]::Exists("$($folderPath)/$($file)")) {
    Write-Progress "Installing EDCRE" -Id 3 -status "Step 2/3: Extracting EDCRE..." -PercentComplete 33
    
    # Extract to temp directory first
    $tempPath = "$($folderPath)/temp_extract"
    Expand-Archive "$($folderPath)/$($file)" -DestinationPath $tempPath
    
    # Move contents from subdirectory to edcre directory
    $subdir = Get-ChildItem -Path $tempPath -Directory | Select-Object -First 1
    if ($subdir) {
        Get-ChildItem -Path $subdir.FullName -Force | Move-Item -Destination $folderPath -Force
    } else {
        Get-ChildItem -Path $tempPath -Force | Move-Item -Destination $folderPath -Force
    }
    
    # Clean up temp directory
    Remove-Item -Path $tempPath -Recurse -Force
    
    Write-Progress "Installing EDCRE" -Id 3 -status "Step 3/3: Cleaning up..." -PercentComplete 66
    Remove-Item "$($folderPath)/$($file)" -Force
    
    Write-Progress "Installing EDCRE" -Id 3 -status "Installation successful!" -Completed
    Write-Host "EDCRE installation successful!";
}
else {
    Write-Progress "Installing EDCRE" -Id 3 -status "Installation failed!" -Completed
    Write-Host "EDCRE installation failed!";
}

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
Write-Host ""