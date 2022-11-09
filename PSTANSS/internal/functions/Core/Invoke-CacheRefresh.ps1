function Invoke-CacheRefresh {
    <#
    .Synopsis
        Invoke-CacheRefresh

    .DESCRIPTION
        Invokes api calls to fill mostly used lookup values

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .EXAMPLE
        Invoke-CacheRefresh -Token $token

        Example

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(Mandatory = $true)]
        [TANSS.Connection]
        $Token
    )

    Write-PSFMessage -Level Verbose -Message "Start updating lookup cache from current tickets in TANSS" -Tag "Cache"

    $tickets = @()
    $tickets += Get-TANSSTicket -MyTickets -Token $token
    $tickets += Get-TANSSTicket -NotAssigned -Token $token
    $tickets += Get-TANSSTicket -AllTechnician -Token $token
    Write-PSFMessage -Level Verbose -Message "Built cache from $($tickets.count) tickets" -Tag "Cache"

    $null = Get-TANSSVacationAbsenceSubType -Token $token
    $null = Get-TANSSDepartment -Token $token
    $null = Get-TANSSTicketStatus -Token $token
    $null = Get-TANSSTicketType -Token $token
}
