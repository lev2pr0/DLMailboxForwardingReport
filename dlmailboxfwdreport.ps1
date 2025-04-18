<#
Please review README.md(https://github.com/lev2pr0/dlmailboxfwdreport/blob/main/README.md) before running this script
Main function to determine Exchange Online or On-premise and gather domains
#>
Function dlmailboxfwdreport{
    param(
        [string[]]$Domains=@(),
        [switch]$onpremEX,
        [string]$OutputPath
    )

    # Connect to Exchange Online and skips if -onpremEX switch is found
    if (-not $onpremEX) {
        Write-Host "Connecting to Exchange Online...`n" -ForegroundColor Cyan
        try { # Check for existing Exchange Online sessions
        $exchSessions = (Get-ConnectionInformation | Where-Object {$_.name -like "*ExchangeOnline*"})
        if ($exchSessions.count -lt 1) { # Connect to Exchange Online if no existing session
            Connect-ExchangeOnline
        } else { # Confirm existing connection to Exchange Online
            Write-Host "Already connected to Exchange Online.`n" -ForegroundColor Green
        }
    } catch { # Handle errors connecting to Exchange Online
        Write-Host "Error connecting to Exchange Online: $_`n" -ForegroundColor Red
        Write-Host "If using Exchange Management Shell on Exchange Server, then rerun using -onpremEX switch `n" -ForegroundColor Red
        Write-Host "Existing script. Goodbye.`n" -ForegroundColor Red
        return
            }
        } else { # Skip Exchange Online session check and connection
            Write-Host "Skipping Exchange Online connection as -onpremEX is provided.`n" -ForegroundColor Cyan
    }

    # Gather domains to consider internal for report
    if (($Domains.count -lt 1) -or ($Domains[0].length -lt 1)) {    
    $Domains = ((Read-host "Type in a comma-separated list of your email domains, IE domain1.com,domain2.com") -replace ('@|"| ','')) -split ","
    
        # Validate domains
        $Domains = $Domains | Where-Object { $_ -match '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' }
        if ($Domains.count -lt 1) { # Handle errors for invalid user inputs
            Write-Host "No valid domains provided." -ForegroundColor Red
            Write-Host "Please provide a valid domain list in the format: domain1.com,domain2.com`n" -ForegroundColor Red
            Write-Host "Existing script. Goodbye.`n" -ForegroundColor Red
            return
            }
    }

    # Reporting function start
    Write-Host "Ready to run your report `n" -ForegroundColor Green
    # Prompt user for report type
    do {
        Write-Host "Available reports: `n" -ForegroundColor Yellow
        Write-Host "1. publicDL - Designed to generate a report of members for Distribution Lists open to external senders" -ForegroundColor Yellow
        Write-Host "2. mailboxfwd - Designed to generate a report on configured forwarding SMTP addresses on user or shared mailboxes `n" -ForegroundColor Yellow
        Write-Host "Type 'exit' to quit the script. `n" -ForegroundColor Yellow
        $reportType = Read-Host "Enter the report type you want to run (publicDL or mailboxfwd)"
        
        if ([string]::IsNullOrEmpty($reportType)) {
            Write-Host "Input cannot be empty. Please enter a valid report type." -ForegroundColor Red
        } elseif ($reportType -notin @("publicDL", "mailboxfwd", "exit")) {
            Write-Host "Invalid report type. Please enter 'publicDL' or 'mailboxfwd'" -ForegroundColor Red
        }
    } while ([string]::IsNullOrEmpty($reportType) -or $reportType -notin @("publicDL", "mailboxfwd", "exit"))

    # Run functions based on user input
    if ($reportType -eq "publicDL") {
            publicDL_report
        } elseif ($reportType -eq "mailboxfwd") {
            mailboxfwd_report
        } elseif ($reportType -eq "exit") {
            Write-Host "Existing script. Thanks. Goodbye.`n" -ForegroundColor Red
            return
        }
}

# Export results to CSV for report function
Function report_csv {
    param(
        [array]$results,
        [string]$reportType,
        [string]$OutputPath = "$($reportType)_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv" # Unique output path for each report
    )
    if ($results.Count -gt 0) {
        try {
            Write-Host "Exporting results to CSV...`n" -ForegroundColor Cyan
            $results | Export-Csv -Path $OutputPath -NoTypeInformation -Force
            Write-Host "Report exported to $OutputPath" -ForegroundColor Green
        } catch {
            Write-Host "Error exporting results to CSV: $_ `n" -ForegroundColor Red
            }
        } else {
            Write-Host "No results to export. `n" -ForegroundColor Yellow
            return
        }
}

# Public DL Report Function to generate a report for public distribution lists
Function publicDL_report {
    # Get all distribution groups that are public
    try {
        Write-Host "Running Public Distribution Report... `n" -ForegroundColor Cyan
        $public_groups = Get-DistributionGroup | Where-Object {$_.RequireSenderAuthenticationEnabled -eq $false}
    } catch {
        Write-Host "Error retrieving public distribution group: $($_.PrimarySmtpAddress): $_ `n" -ForegroundColor Red
        return
    }

    # Get members of each public distribution group
    $results = @()
    $public_groups | ForEach-Object {
        Write-host "Processing members of $($_.PrimarySmtpAddress) `n" -ForegroundColor Cyan
        $members = Get-DistributionGroupMember -Identity $_.name
        foreach ($member in $members) {
             # Get recipient details for each member
                $recipient = Get-Recipient -Identity $member.name
                if ($null -ne $recipient) {
                    $recipientDomain = ($recipient.PrimarySmtpAddress -split "@")[1]
                    $results += [PSCustomObject]@{
                        PrimarySmtpAddress = $recipient.PrimarySmtpAddress
                        Organization = if ($recipientDomain -in $Domains) { "Internal" } else { "External" }
                        GroupEmail = $_.PrimarySmtpAddress
                        GroupType = $_.RecipientTypeDetails
                    }
                } else {
                    Write-Host "Recipient not found for member $($member.name) `n" -ForegroundColor Yellow
                }
            }
        }

    # Export results to CSV
    report_csv -results $results -reportType "publicDLreport"
    # Display results in console  
}

#Mailbox Forward Report Function to pull forwarding report for User and Shared Mailbox
Function mailboxfwd_report {
    # Get all user and shared mailboxes with forwardingSMTPaddress
    Write-Host "Running Mailbox Forwarding Report...`n" -ForegroundColor Cyan
    try { 
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {
        $_.RecipientTypeDetails -eq "UserMailbox" -or $_.RecipientTypeDetails -eq "SharedMailbox"
        } | Where-Object {$_.ForwardingSmtpAddress -ne $null}
    } catch { # Handle errors for each mailbox
        Write-Host "Error retrieving mailboxes: $_ `n" -ForegroundColor Red
        return
    }

    # Search for mailboxes with forwarding addresses configured
    # Split domains to compare if Internal or External
    $results = @()
    $mailboxes | ForEach-Object {
        $forwardingaddress = $_.ForwardingSmtpAddress.ToString()
        $domainPart = ($forwardingaddress -split "@")[1]
        $isInternal = $Domains -contains $domainPart
        # Build report of mailboxes with forwardingSMTPaddress configured
        $results += [PSCustomObject]@{
            DisplayName             = $_.DisplayName
            PrimarySmtpAddress      = $_.PrimarySmtpAddress
            ForwardingSmtpAddress   =  if ($_.ForwardingSmtpAddress -match ":") { ($forwardingaddress -split ":")[1] } else { $_.ForwardingSmtpAddress }
            DeliverToMailboxAndForward = $_.DeliverToMailboxAndForward
            Organization        = if ($isInternal) { "Internal" } else { "External" }
        }
    }

    # Export results to CSV
    report_csv -results $results -reportType "mailboxfwdreport"
    # Display results in console    
}

#Call to main function dlmailboxfwdreport to determine Exchange Online or On-premise, gather domains, and run report functions

dlmailboxfwdreport

