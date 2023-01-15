function Get-TANSSTicketContent {
    <#
    .Synopsis
        Get-TANSSTicketContent

    .DESCRIPTION
        Retreive the various entries from a ticket.
        Entries can be a comment, activity, mail, document, image

    .PARAMETER Token
        The TANSS.Connection token to access api

        If not specified, the registered default token from within the module is going to be used

    .EXAMPLE
        PS C:\> Verb-Noun

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

        [ValidateNotNullOrEmpty()]
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
                        $object = [TANSS.TicketDocument]@{
                            BaseObject = $document
                            Id         = $document.id
                        }
                        if ($responseDocumentUri.content) {
                            $object.Key = $responseDocumentUri.content.key
                            $object.DownloadUri = Format-ApiPath -Path $responseDocumentUri.content.url
                        }

                        [TANSS.TicketContent]@{
                            TicketId = $object.TicketId
                            Type     = "Document"
                            Id       = $object.Id
                            Date     = $object.Date
                            Text     = $object.Description
                            Object   = $object
                        }
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
                        $object = [TANSS.TicketImage]@{
                            BaseObject = $image
                            Id         = $image.id
                        }

                        [TANSS.TicketContent]@{
                            TicketId = $object.TicketId
                            Type     = "Image"
                            Id       = $object.Id
                            Date     = $object.Date
                            Text     = $object.Description
                            Object   = $object
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
                    Write-PSFMessage -Level Verbose -Message "Found content in ticket $($ticketIdItem), going to parse content"  -Tag "TicketContent", "Query", "QueryHistory"

                    # Get comments
                    if ( ($Type | Where-Object { $_ -in @("All", "Comment") }) ) {
                        Write-PSFMessage -Level Verbose -Message "Working through $($response.content.comments.count) comment$(if($response.content.comments.count -gt 1) {'s'})"  -Tag "TicketContent", "Query", "QueryHistory", "Comment"

                        $content += foreach ($comment in $response.content.comments) {
                            $object = [TANSS.TicketComment]@{
                                BaseObject = $comment
                                ID         = $comment.id
                                TicketId   = $ticketIdItem
                            }

                            [TANSS.TicketContent]@{
                                TicketId = $object.TicketId
                                Type     = "Comment"
                                Id       = $object.Id
                                Date     = $object.Date
                                Text     = $object.Description
                                Object   = $object
                            }
                        }
                    }

                    # Get activities
                    if ( ($Type | Where-Object { $_ -in @("All", "Activity") }) ) {
                        Write-PSFMessage -Level Verbose -Message "Working through $($response.content.supports.count) $(if($response.content.supports.count -gt 1) {'Activities'} else {'Activity'})"  -Tag "TicketContent", "Query", "QueryHistory", "Activity"

                        $content += foreach ($activity in $response.content.supports) {
                            $object = [TANSS.TicketActivity]@{
                                BaseObject = $activity
                                ID         = $activity.id
                            }

                            [TANSS.TicketContent]@{
                                TicketId = $object.TicketId
                                Type     = "Activity"
                                Id       = $object.Id
                                Date     = $object.Date
                                Text     = $object.Description
                                Object   = $object
                            }
                        }
                    }

                    # Get mails
                    if ( ($Type | Where-Object { $_ -in @("All", "Mail") }) ) {
                        Write-PSFMessage -Level Verbose -Message "Working through $($response.content.mails.count) mail$(if($response.content.mails.count -gt 1) {'s'})"  -Tag "TicketContent", "Query", "QueryHistory", "Mail"

                        $content += foreach ($mail in $response.content.mails) {
                            $object = [TANSS.TicketMail]@{
                                BaseObject = $mail
                                ID         = $mail.id
                                TicketId   = $ticketIdItem
                            }

                            [TANSS.TicketContent]@{
                                TicketId = $object.TicketId
                                Type     = "Mail"
                                Id       = $object.Id
                                Date     = $object.Date
                                Text     = $object.Subject
                                Object   = $object
                            }
                            #>
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

            # Output result
            if($content) {
                Write-PSFMessage -Level Verbose -Message "Output $(([array]$content).count) content record$(if(([array]$content).count -gt 1){'s'}) from ticket $($ticketIdItem)" -Tag "TicketContent", "Query", "OutputResult"

                $content | Sort-Object Date

            } else {
                Write-PSFMessage -Level Significant -Message "No $(if($Type -notlike "All") {'matching'}) content found in ticket $($ticketIdItem)" -Tag "TicketContent", "Query", "OutputResult", "NoData"
            }
        }
    }

    end {}
}
