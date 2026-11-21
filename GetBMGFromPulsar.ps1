param (
    [Parameter(Mandatory=$true)]
    [string]$InPath,
    [string]$OutPath,
    [switch]$Decode = $false
)

$Magic = [byte[]](0x50, 0x55, 0x4C, 0x53, 0x00, 0x00, 0x00, 0x03) # "PULS" and version 3
$BMGMagic = [byte[]](0x4D, 0x45, 0x53, 0x47, 0x62, 0x6D, 0x67, 0x31) # "MESGbmg1"

### Verify the provided file is Pulsar file ###
# Verify the file extension
[string]$InExtension = [System.IO.Path]::GetExtension($InPath).ToLower()
if ($InExtension -ne ".pul")
{
    Write-Error "Not a Pulsar file. Abort!"
    exit
}

# Read the *.pul file
$InFs = [System.IO.File]::OpenRead($InPath)

# Verify the first 8 bytes is matched
$InMagicBytes = New-Object byte[] 8
[void]$InFs.Read($InMagicBytes, 0, 8)
if (-not [System.Linq.Enumerable]::SequenceEqual($InMagicBytes, $Magic))
{
    Write-Error "Not a Config.pul file or the file is broken. Abort!" -Category InvalidData
    exit
}

# Get the offset to BMG
[void]$InFs.Seek(0x10, [System.IO.SeekOrigin]::Begin)
$InBMGOffset = New-Object byte[] 4
[void]$InFs.Read($InBMGOffset, 0, 4)
[Array]::Reverse($InBMGOffset)
$InBMGOffset = [BitConverter]::ToUInt32($InBMGOffset)

# Check the magic
[void]$InFs.Seek($InBMGOffset, [System.IO.SeekOrigin]::Begin)
$InBMGMagic = New-Object byte[] 8
[void]$InFs.Read($InBMGMagic, 0, 8)

if (-not [System.Linq.Enumerable]::SequenceEqual($InBMGMagic, $BMGMagic))
{
    Write-Error "Could not find BMG data in your Config.pul. Abort!" -Category InvalidData
    exit
}

# Get the size of BMG
$InBMGSize = New-Object byte[] 4
[void]$InFs.Read($InBMGSize, 0, 4)
[Array]::Reverse($InBMGSize)
$InBMGSize = [BitConverter]::ToUInt32($InBMGSize)

# Finally get the whole BMG data from Config.pul
[void]$InFs.Seek(-0x0c, [System.IO.SeekOrigin]::Current)
$InBMGData = New-Object byte[] $InBMGSize
[void]$InFs.Read($InBMGData, 0, $InBMGSize)

# Output the BMG file
if ([string]::IsNullOrEmpty($OutPath))
{
    Add-Type -AssemblyName System.Windows.Forms

    $SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveDialog.Filter = "BMG file (*.bmg)|*.bmg"
    $SaveDialog.FileName = [System.IO.Path]::ChangeExtension($InPath, "bmg")

    if ($SaveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $OutPath = $SaveDialog.FileName
    } else
    {
        Write-Error "Abort!" -Category OperationStopped
        exit
    }
}

[System.IO.File]::WriteAllBytes($OutPath, $InBMGData)

if ($Decode)
{
    Write-Host "Done. Now begin to decode the BMG using wbmgt." -ForegroundColor Green

    if ($null -eq (Get-Command "wbmg.exe" -ErrorAction SilentlyContinue))
    {
        Write-Error "Attempted to decode the BMG but wbmgt not found.`r`nMake sure Wiimms SZS Tools has been installed. Abort!" -Category NotInstalled
        exit
    }

    & "wbmgt.exe" decode $OutPath -o
}

Write-Host "Done." -ForegroundColor Green
