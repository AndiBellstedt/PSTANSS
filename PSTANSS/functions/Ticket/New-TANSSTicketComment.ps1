function New-TANSSTicketComment {
    <#
    .Synopsis
        New-TANSSTicketComment

    .DESCRIPTION
        Add a comment to a ticket

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

    .PARAMETER PassThru
        Outputs the result to the console

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .EXAMPLE
        Verb-Noun

        Description

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PSTANSS
    #>
    [CmdletBinding(
        DefaultParameterSetName = "ByTicketId",
        SupportsShouldProcess = $true,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByTicketId",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [int]
        $TicketID,

        [Parameter(
            ParameterSetName = "ByTicket",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.Ticket]
        $Ticket,

        [string]
        $Title,

        [Alias("Description")]
        [string]
        $Text,


        [Alias("Internal")]
        [bool]
        $IsInternal = $true,

        [switch]
        $Pinned,

        [TANSS.Connection]
        $Token
    )

    begin {
        if (-not $Token) { $Token = Get-TANSSRegisteredAccessToken }
        Assert-CacheRunspaceRunning
    }

    process {
        $parameterSetName = $pscmdlet.ParameterSetName
        Write-PSFMessage -Level Debug -Message "ParameterNameSet: $($parameterSetName)"

        if ($parameterSetName -like "ByTicket") { $TicketID = $Ticket.id }

        Write-PSFMessage -Level Verbose -Message "Working on ticket ID $($TicketID)" -Tag "TicketComment", "Add"

        # Prepare variables for rest call
        if ($Pinned) { $queryParameter = "?pinned=true" } else { $queryParameter = "?pinned=false" }
        $apiPath = Format-ApiPath -Path "api/v1/tickets/$ticketID/comments$($queryParameter)"
        $body = @{
            "title"    = $Title
            "content"  = $Text
            "internal" = $IsInternal
        }

        if ($pscmdlet.ShouldProcess("$(if($IsInternal -eq $true) {"Internal"}else{"Public"}) comment $(if($Title){"with title '$($Title)' "})on Ticket $($TicketID)", "New")) {
            Write-PSFMessage -Level Verbose -Message "New $(if($IsInternal -eq $true) {"Internal"}else{"Public"}) comment $(if($Title){"with title '$($Title)' "})on Ticket $($TicketID)" -Tag "TicketComment", "Add"

            $response = Invoke-TANSSRequest -Type POST -ApiPath $apiPath -Body $body -Token $Token

            if ($response.content) {
                Write-PSFMessage -Level Verbose -Message "$($response.meta.text)" -Tag "TicketComment", "Added"

                # prepare comment object for output
                $object = [PSCustomObject]@{
                    id         = $response.content.id
                    date       = $response.content.date
                    employeeId = $response.content.employeeId
                    categoryId = $response.content.categoryId
                    title      = $response.content.title
                    content    = $response.content.content
                    internal   = $response.content.internal
                }

                # output result
                [TANSS.TicketComment]@{
                    BaseObject = $object
                    ID         = $object.id
                    TicketId   = $response.content.commentOfId
                }
            }
        }
    }

    end {}
}
