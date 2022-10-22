function Get-TANSSTicketContent {
    <#
    .Synopsis
        Get-TANSSTicketContent

    .DESCRIPTION
        Retreive the various entries from a ticket.
        Entries can be a comment, activity, mail, document, image

    .PARAMETER Token
        AccessToken object to register as default connection for TANSS

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
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(
            ParameterSetName = "ByTicketId",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [int[]]
        $TicketID,

        [Parameter(
            ParameterSetName = "ByTicket",
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [TANSS.Ticket[]]
        $Ticket,

        [ValidateSet("All", "Comment", "Activity", "Mail", "Document", "Image")]
        [string[]]
        $Type = "All",

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

        if ($parameterSetName -like "ByTicket") {
            $inputobjectTicketCount = ([array]$Ticket).Count
            Write-PSFMessage -Level System -Message "Getting IDs of $($inputobjectTicketCount) ticket$(if($inputobjectTicketCount -gt 1){'s'})"  -Tag "TicketContent", "CollectInputObjects"
            [array]$TicketID = $Ticket.id
        }

        <#
        $ticketIdItem = 98791
        $ticketIdItem = 124861
        #>
        foreach ($ticketIdItem in $TicketID) {
            Write-PSFMessage -Level Verbose -Message "Working on ticket ID $($ticketIdItem)"  -Tag "TicketContent", "Query"
            $content = @()

            # Get documents, if included in Type filter
            if ( ($Type | Where-Object { $_ -in @("All", "Document") }) ) {
                Write-PSFMessage -Level Verbose -Message "Getting documents from ticket $($ticketIdItem)"  -Tag "TicketContent", "Query", "QueryDocuments"

                $apiPath = Format-ApiPath -Path "api/v1/tickets/$ticketIdItem/documents"
                $response = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
                Push-DataToCacheRunspace -MetaData $response.meta

                if ($response.content) {
                    Write-PSFMessage -Level Verbose -Message "Found $($response.content.count) documents"  -Tag "TicketContent", "Query", "QueryDocuments"
                    $content += foreach ($document in $response.content) {
                        # create output objects, but first query download uri

                        # build api path
                        $apiPath = Format-ApiPath -Path "api/v1/tickets/$ticketIdItem/documents/$($document.id)"

                        # query download uri
                        $responseDocumentUri = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token

                        # create output
                        $output = [TANSS.TicketDocument]@{
                            BaseObject = $document
                            Id         = $document.id
                        }
                        if ($responseDocumentUri.content) {
                            $output.Key = $responseDocumentUri.content.key
                            $output.DownloadUri = Format-ApiPath -Path $responseDocumentUri.content.url
                        }

                        # Output object
                        $output
                    }
                } else {
                    Write-PSFMessage -Level Verbose -Message "No documents found"  -Tag "TicketContent", "Query", "QueryDocuments"
                }
            }

            # Get images, if included in Type filter
            if ( ($Type | Where-Object { $_ -in @("All", "Image") }) ) {
                Write-PSFMessage -Level Verbose -Message "Getting images from ticket $($ticketIdItem)"  -Tag "TicketContent", "Query", "QueryImages"

                $apiPath = Format-ApiPath -Path "api/v1/tickets/$ticketIdItem/screenshots"
                $response = Invoke-TANSSRequest -Type GET -ApiPath $apiPath -Token $Token
                Push-DataToCacheRunspace -MetaData $response.meta

                if ($response.content) {
                    Write-PSFMessage -Level Verbose -Message "Found $($response.content.count) images"  -Tag "TicketContent", "Query", "QueryImages"
                    $content += foreach ($image in $response.content) {
                        # create output objects
                        [TANSS.TicketImage]@{
                            BaseObject = $image
                            Id         = $image.id
                        }
                    }
                } else {
                    Write-PSFMessage -Level Verbose -Message "No images found"  -Tag "TicketContent", "Query", "QueryImages"
                }
            }

            # Get Comments, Activities, Mails
            if ( ($Type | Where-Object { $_ -in @("All", "Comment", "Activity", "Mail") }) ) {
                Write-PSFMessage -Level Verbose -Message "Getting comments, mails and activities from ticket $($ticketIdItem)"  -Tag "TicketContent", "Query", "QueryHistory"

                $apiPath = Format-ApiPath -Path "api/v1/tickets/history/$ticketIdItem"
                $response = Invoke-TANSSRequest -Type GET -ApiPath "backend/api/v1/tickets/history/$ticketID" -Token $Token
                Push-DataToCacheRunspace -MetaData $response.meta

                if ($response.content) {
                    # Get comments
                    if ( ($Type | Where-Object { $_ -in @("All", "Comment") }) ) {
                        $content += foreach ($comment in $response.content.comments) {
                            [TANSS.TicketComment]@{
                                BaseObject = $comment
                                ID = $comment.id
                            }
                        }
                    }

                    # Get activities
                    if ( ($Type | Where-Object { $_ -in @("All", "Activity") }) ) {
                        $content += foreach ($activity in $response.content.supports) {
                            [TANSS.TicketActivity]@{
                                BaseObject = $activity
                                ID = $activity.id
                            }
                        }
                    }

                    # Get mails
                    if ( ($Type | Where-Object { $_ -in @("All", "Mail") }) ) {
                        $content += foreach ($mail in $response.content.supports) {
                            [TANSS.TicketMail]@{
                                BaseObject = $mail
                                ID = $mail.id
                            }
                        }
                    }
                } else {
                    $_type = $Type | Where-Object { $_ -notlike "All" }
                    if ($_type) {
                        $_type = [string]::Join(', ', [array]$_type)
                    } else {
                        $_type = [string]::Join(', ', @("Comment", "Activity", "Mail"))
                    }
                    Write-PSFMessage -Level Verbose -Message "No $_type data found"  -Tag "TicketContent", "Query", "QueryHistory"
                }
            }

            $content | ft id, BaseObject

            #Stop-PSFFunction -Message "Error something" -EnableException $true -Cmdlet $pscmdlet -Tag "TicketContent", "What", "TypeException"

        }
    }

    end {}
}
