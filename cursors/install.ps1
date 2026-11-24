# Sets the RAVYN Neon cursors for the current user. Add -WhatIf to see the changes without making them.
# Windows loads the files from this folder, so keep the folder where it is.
# Undo: Settings > Bluetooth & devices > Mouse > Additional mouse settings > Pointers > scheme "Windows Default".
[CmdletBinding(SupportsShouldProcess)]
param()

$map = [ordered]@{
    Arrow = 'Arrow.cur'; Help = 'Help.cur'; AppStarting = 'Working.ani'; Wait = 'Busy.ani'
    Crosshair = 'Cross.cur'; IBeam = 'Text.cur'; NWPen = 'Pen.cur'; No = 'No.cur'
    SizeNS = 'SizeNS.cur'; SizeWE = 'SizeWE.cur'; SizeNWSE = 'SizeNWSE.cur'; SizeNESW = 'SizeNESW.cur'
    SizeAll = 'Move.cur'; UpArrow = 'Up.cur'; Hand = 'Link.cur'; Pin = 'Pin.cur'; Person = 'Person.cur'
}
$key = 'HKCU:\Control Panel\Cursors'

foreach ($name in $map.Keys) {
    $file = Join-Path $PSScriptRoot ('RAVYN_' + $map[$name])
    if (-not (Test-Path $file)) { throw "Missing cursor file: $file" }
    if ($PSCmdlet.ShouldProcess($name, "point to $file")) { Set-ItemProperty $key -Name $name -Value $file }
}
if ($PSCmdlet.ShouldProcess('scheme name', 'set to RAVYN Neon')) { Set-ItemProperty $key -Name '(default)' -Value 'RAVYN Neon' }

if ($PSCmdlet.ShouldProcess('cursors', 'reload now')) {
    Add-Type -Namespace RavynNeon -Name Native -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint action, uint param, System.IntPtr value, uint flags);'
    [void][RavynNeon.Native]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x03)   # SPI_SETCURSORS
}
