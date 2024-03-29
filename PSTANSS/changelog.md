﻿# Changelog
## 1.0.0 New version (2023-09-21)
- Finally production release
- Fix: WhatIf behaviour on various commands lead to unexpected WhatIf- & sometimes error-output. -> this behavious goes back that the functions calls subfunktions wihtin the module following the WhatIf preference correctly.

## 0.6.0 New version (2023-08-20)
- New: Timestamp & ProjectPhase functions
    - Projects (basically alias functions ticket functions)
        - New-TANSSProject
        - Remove-TANSSProject
        - Get-TANSSProject
    - Project phase management
        - New-TANSSProjectPhase
        - Set-TANSSProjectPhase
        - Remove-TANSSProjectPhase
        - Get-TANSSProjectPhase
    - TimeStamp (only functional when module is licensed within the software)
        - New-TANSSTimeStamp
        - Remove-TANSSTimeStamp
        - Get-TANSSTimeStamp
    - Core functions
        - New-TANSSServiceToken:\
          create Tokens from TANSS API keys
- Update:
    - Core functions
        - Invoke-TANSSRequest:\
          Parameter 'BodyForceArray' -> Tells the function always to invoke the data in the body as a JSON array formatted string

## 0.5.1 BugFix version (2023-07-09)
 - Fix: typo in command "technican" -> "technician"
 - Update:
    - Get-TANSSTechnican - Rename commandto "Get-TANSSTechnician"
    - Get-TANSSTicket - Pename parameter "TicketWithTechnicanRole" to "TicketWithTechnicianRole"

## 0.5.0 Frist release (2023-01-27)
 - New: Frist Version with commands
    - API core service commands
        - Connect-TANSS
        - Invoke-TANSSRequest
        - Get-TANSSRegisteredAccessToken
        - Register-TANSSAccessToken
        - Update-TANSSAccessToken
        - Find-TANSSObject
        - Get-TANSSDepartment
    - Tickets
        - New-TANSSTicket
        - Get-TANSSTicket
        - Set-TANSSTicket
        - Remove-TANSSTicket
        - Get-TANSSTicketContent
        - Get-TANSSTicketActivity
        - Get-TANSSTicketComment
        - Get-TANSSTicketDocument
        - Get-TANSSTicketImage
        - Get-TANSSTicketMail
        - New-TANSSTicketComment
        - Remove-TANSSTicketComment
        - Get-TANSSTicketStatus
        - Get-TANSSTicketType
    - Employees
        - Get-TANSSTechnican
        - Get-TANSSEmployee
        - New-TANSSEmployee
    - Vacation
        - Get-TANSSVacationAbsenceSubType
        - Get-TANSSVacationRequest
        - New-TANSSVacationRequest
        - Set-TANSSVacationRequestStatus
        - Approve-TANSSVacationRequest
        - Deny-TANSSVacationRequest
        - Remove-TANSSVacationRequest
        - Set-TANSSVacationRequest
        - Request-TANSSVacationRequestObject
        - Out-TANSSVacationRequestPdf
        - Get-TANSSVacationEntitlement
        - Set-TANSSVacationEntitlemen
 - Upd: ---
 - Fix: ---