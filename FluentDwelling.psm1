<#
.Synopsis
   Gets the powerline modem attached to the specified serial port.
.DESCRIPTION
   Gets the powerline modem attached to the specified serial port. The powerline modem
   controls all the different Insteon and X10 devices paired with it. 
.EXAMPLE
   Get-PowerlineModem -PortName "COM4"
#>
function Get-PowerlineModem
{
    [CmdletBinding()]
    [OutputType([SoapBox.FluentDwelling.Plm])]
    Param
    (
        # The name of the serial port the powerline modem is attached to. E.G COM4
        [Parameter(Mandatory=$true,
                   Position=0)]
        [String]$PortName
    )

    End
    {
        New-Object -TypeName SoapBox.FluentDwelling.Plm -ArgumentList $PortName
    }
}

<#
.Synopsis
   Gets the devices in the powerline modem's database.
.DESCRIPTION
   Gets the devices in the powerline modem's database. This cmdlet will return all the devices and attempt
   to connect to each of them. Items returned from this will be inheritors of DeviceBase.
.EXAMPLE
   Get-Device -PortName "COM3"
#>
function Get-Device
{
    [CmdletBinding()]
    [OutputType([SoapBox.FluentDwelling.Devices.DeviceBase])]
    Param
    (
        # The powerline modem to retrieve devices from.
        [Parameter(Mandatory=$true,
                   ParameterSetName="Plm",
                   ValueFromPipeline=$true,
                   Position=0)]
        [SoapBox.FluentDwelling.Plm]$PowerlineModem,

        # The serial port the powerline modem is connected to retrieve devices from.
        [Parameter(Mandatory=$true,
                   ParameterSetName="PortName",
                   ValueFromPipeline=$true,
                   Position=0)]
        [string]$PortName,
        [string]$DeviceId
    )

    Process
    {
        [SoapBox.FluentDwelling.Devices.DeviceBase]$Device = $null
        if ($PowerlineModem -ne $null)
        {
            if ($DeviceId -ne $null -and $DeviceId -ne "")
            {
                Write-Verbose "Connecting to device $DeviceId"
                if (-not $PowerlineModem.Network.TryConnectToDevice($DeviceId, [ref]$Device))
                {
                    Write-Error $PowerlineModem.Exception
                    return
                }
                else
                {
                    $Device
                }
            }
            else
            {
                $PowerlineModem.GetAllLinkDatabase().Records | Foreach-Object {
                    Write-Verbose "Connecting to device $($_.DeviceId)"

                    if (-not $PowerlineModem.Network.TryConnectToDevice($_.DeviceId, [ref]$Device))
                    {
                        Write-Error $PowerlineModem.Exception
                        return
                    }
                    else
                    {
                        $Device
                    }
                }
            }
        }
        else
        {
            Get-PowerlineModem -PortName $PortName | Get-Device
        }
    }
}

<#
.Synopsis
   Sets a lighting device to the specified state.
.DESCRIPTION
   Sets a lighting device to the specified state. This cmdlet supports On and Off states. Ramping is only
   supported by dimmable lights.
.EXAMPLE
    $Device = Get-Device "COM3" 
   Set-Light -Light $Device -State On
#>
function Set-Light
{
    [CmdletBinding()]
    Param
    (
        # The device to control
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [SoapBox.FluentDwelling.Devices.LightingControl]
        $Light,
        # The desired device state.
        [ValidateSet("On", "Off")]
        $State,
        # Whether to ramp on or off
        [Switch]$Ramp,
        # The level to ramp on to (1-255). Default is 128 (50%).
        [ValidateRange(1, 255)]
        [int]$RampOnLevel = 128
    )

    Process
    {
        if ($Ramp)
        {
            if ($Light -isnot [SoapBox.FluentDwelling.Devices.DimmableLightingControl])
            {
                Write-Error "Only DimmableLightingControl's support ramping."
                return
            }

            switch($State)
            {
                "On" { $Light.RampOn(128) }
                "Off" { $Light.RampOff() }
            }
        }
        else
        {
            switch($State)
            {
                "On" { $Light.TurnOn() }
                "Off" { $Light.TurnOff() }
            }
        }
    }
}
