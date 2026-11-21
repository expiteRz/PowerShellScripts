param (
    [Parameter(Mandatory = $true)]
    [string]$InBrstmPath,

    [string]$OutBrstmPath
)

function New-Fast-Brstm
{
    Write-Host -NoNewLine "Generating a fast BRSTM: $InBrstmPath -> $OutBrstmPath..."

    [byte[]]$InBrstmBytes = [System.IO.File]::ReadAllBytes($InBrstmPath)
    $InBrstmSampleRate = [byte[]]$InBrstmBytes[0x64..0x65]
    $InBrstmSampleRate = [System.Buffers.Binary.BinaryPrimitives]::ReadUInt16BigEndian($InBrstmSampleRate)

    [uint16]$OutBrstmSampleRate = 0xB844
    if ($InBrstmSampleRate -eq 48000)
    {
        $OutBrstmSampleRate = 0xC880
    }

    [byte[]]$OutBrstmSampleRate = [BitConverter]::GetBytes($OutBrstmSampleRate)
    [Array]::Reverse($OutBrstmSampleRate)

    $OutBrstmBytes = $InBrstmBytes
    [Array]::Copy($OutBrstmSampleRate, 0, $OutBrstmBytes, 0x64, $OutBrstmSampleRate.Length)

    [System.IO.File]::WriteAllBytes($OutBrstmPath, $OutBrstmBytes)

    Write-Host " Done."
}

if ([string]::IsNullOrEmpty($OutBrstmPath))
{
    Add-Type -AssemblyName System.Windows.Forms

    $SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveDialog.Filter = "BRSTM file (*.brstm)|*.brstm"
    $SaveDialog.FileName = $InBrstmPath

    if ($SaveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $OutBrstmPath = $SaveDialog.FileName
        New-Fast-Brstm
        $SaveDialog.Dispose()
    }
} else
{
    New-Fast-Brstm
}
