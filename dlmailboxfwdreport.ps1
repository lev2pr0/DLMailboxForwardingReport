
 Function report_csv {
     param(
         [array]$results
     )
     if ($results.Count -gt 0) {
         try {
             $results | Export-Csv -Path $OutputPath -NoTypeInformation
             Write-Host "Report exported to $OutputPath" -ForegroundColor Green
         } catch {
             Write-Host "Error exporting results to CSV: $_" -ForegroundColor Red
         }
     } else {
         Write-Host "No results to export." -ForegroundColor Yellow
     }
 }
 
 # Public DL Report Function to generate a report for public distribution lists
 Function publicDL_report {
     # Get all distribution groups that are public
     try {
         $public_groups = Get-DistributionGroup | Where-Object {$_.RequireSenderAuthenticationEnabled -eq $false}
     } catch {
         Write-Host "Error retrieving public distribution group: $($_.PrimarySmtpAddress): $_" -ForegroundColor Red
         return
     }
 
     # Get members of each public distribution group
     $results = @()
     $public_groups | ForEach-Object {
         Write-host "Processing members of $($_.PrimarySmtpAddress)" -ForegroundColor Cyan
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
                     Write-Host "Recipient not found for member $($member.name)" -ForegroundColor Yellow
                 }
             }
         }
 
     # Export results to CSV
     report_csv -results $results
     # Display results in console  
 }
 
 
 #Mailbox Forward Report Function to pull forwarding report for User and Shared Mailbox
 Function mailboxfwd_report {
     # Get all user and shared mailboxes with forwardingSMTPaddress
     Write-Host "Gathering mailboxes with forwarding addresses..." -ForegroundColor Cyan
     try { 
     $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {
         $_.RecipientTypeDetails -eq "UserMailbox" -or $_.RecipientTypeDetails -eq "SharedMailbox"
         } | Where-Object {$_.ForwardingSmtpAddress -ne $null}
     } catch { # Handle errors for each mailbox
         Write-Host "Error retrieving mailboxes: $_" -ForegroundColor Red
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
     report_csv -results $results
     # Display results in console    
 }
 
 ###########################
 
 #Call of main function to determine Exchange Online or On-premise and gather domains
 main 
 
 #Add logic to check what report to run
 Write-Host "Ready to run your report `n" -ForegroundColor Green
 # Prompt user for report type
 do {
     Write-Host "Available reports: publicDL, mailboxfwd, or both" -ForegroundColor Yellow
     Write-Host "Type 'exit' to quit the script. `n" -ForegroundColor Yellow
     $reportType = Read-Host "Enter the report type you want to run (publicDL, mailboxfwd, both)"
 
     if ([string]::IsNullOrEmpty($reportType)) {
         Write-Host "Input cannot be empty. Please enter a valid report type." -ForegroundColor Red
     } elseif ($reportType -notin @("publicDL", "mailboxfwd", "both", "exit")) {
         Write-Host "Invalid report type. Please enter 'publicDL', 'mailboxfwd', or 'both'." -ForegroundColor Red
     }
 } while ([string]::IsNullOrEmpty($reportType) -or $reportType -notin @("publicDL", "mailboxfwd", "both", "exit"))
 
 # Run functions based on user input
 if ($reportType -eq "publicDL") {
     Write-Host "Running public distribution list report..." -ForegroundColor Green
     publicDL_report
 } elseif ($reportType -eq "mailboxfwd") {
     Write-Host "Running mailbox forwarding report..." -ForegroundColor Green
     mailboxfwd_report
 } elseif ($reportType -eq "both") {
     Write-Host "Running both reports..." -ForegroundColor Green
     publicDL_report
     mailboxfwd_report
 } elseif ($reportType -eq "exit") {
     Write-Host "Exiting script." -ForegroundColor Red
     break
 }
