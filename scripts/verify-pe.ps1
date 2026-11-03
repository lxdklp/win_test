param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [ValidateSet('x64', 'arm64')]
    [string]$Architecture
)

$ErrorActionPreference = 'Stop'
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
if ($bytes.Length -lt 64 -or [BitConverter]::ToUInt16($bytes, 0) -ne 0x5A4D) {
    throw "Not a Windows executable: $Path"
}
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
if ($peOffset -lt 0 -or $peOffset -gt ($bytes.Length - 6)) {
    throw "Invalid PE header offset: $Path"
}
if ([BitConverter]::ToUInt32($bytes, $peOffset) -ne 0x00004550) {
    throw "Invalid PE signature: $Path"
}
$machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
$expected = if ($Architecture -eq 'arm64') { 0xAA64 } else { 0x8664 }
if ($machine -ne $expected) {
    throw ('{0}: expected {1}, got PE machine 0x{2:X4}' -f $Path, $Architecture, $machine)
}
Write-Host "$Path verified as $Architecture"
