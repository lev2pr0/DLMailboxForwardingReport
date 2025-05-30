# Public Distribution Group and Mailbox Forward Report

## Purpose 

The Public Distribution List and Mailbox Forward Reports are developed to enhance security auditing in Microsoft 365’s Exchange Online and on-premises Exchange environments.​

- **Public Distribution List Report:** This automates the generation of reports identifying distribution lists that are open to external senders. Such openness can expose organizations to risks like phishing, whaling, and other social engineering attacks. By listing these distribution lists and their members, administrators can proactively manage and mitigate potential vulnerabilities.​

- **Mailbox Forward Report:** This focuses on detecting user and shared mailboxes that have configured forwarding SMTP addresses. Unauthorized forwarding can be a vector for insider threats and data exfiltration. The report aids in identifying such configurations, allowing for timely intervention to protect sensitive information.​

Together, these tools provide IT administrators and security professionals with automated solutions to monitor and secure their Exchange environments against external and internal threats.​

<br></br>
## Installation

1. Download or make copy of script [here](https://github.com/lev2pr0/DLMailboxForwardingReport/blob/main/dlmailboxfwdreport.ps1)
2. Take note of the script’s path
3. Open PowerShell as an administrator
4. Use ```Set-ExecutionPolicy -ExecutionPolicy <VALUE> -Scope <VALUE>``` to change to acceptable [Execution Policy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.5#-executionpolicy)
5. **Optional:** Navigate to directory location of script using ```cd``` command (Example: ```cd “C:\MyFolder”```)
6. Run PowerShell Script (See [Usage Examples](https://github.com/lev2pr0/DLMailboxForwardingReport/tree/main?tab=readme-ov-file#usage-examples)):
   ```powershell
   .\<scriptname>.ps1 -Parameter1 <VALUE> -Parameter2 <VALUE>
   ```
   ```powershell
   C:\MyFolder\<scriptname>.ps1 -Parameter1 <VALUE> -Parameter2 <VALUE>
   ```

<br></br>
## Parameters 

```powershell
-Domains
```
Specifies the email domains to be used for filtering external members. This parameter accepts a comma-separated list of domains. If not provided, the script will end. 

---

```powershell
-onpremEX
```
Skips the connection to Exchange Online sessions entirely for Exchange Management Shell. Use this switch if you want to use for Exchange On-Premise.

---

```powershell
-OutputPath
```
Allows the user to specify the location and name of the exported file.

<br></br>
## Usage Examples

### Run the function to generate a report for Exchange Online examples
```powershell
.\dlmailboxfwdreport.ps1
```
```powershell
.\dlmailboxfwdreport.ps1 -Domains "domain1.com,domain2.com"
```
```powershell
.\dlmailboxfwdreport.ps1 -Domains "domain1.com,domain2.com" -OutputPath "C:\Reports\ReportName.csv"
```


#

### Run the function to generate a report for Exchange On-Premise examples
```powershell
.\dlmailboxfwdreport.ps1 -onpremEX 
```
```powershell
.\dlmailboxfwdreport.ps1 -Domains "domain1.com,domain2.com" -onpremEX
```
```powershell
.\dlmailboxfwdreport.ps1 -Domains "domain1.com,domain2.com" -OutputPath "C:\Reports\ReportName.csv" -onpremEX 
```

<br></br>
## Demo

### Terminal view 

<img width="807" alt="Terminal_View" src="https://github.com/user-attachments/assets/a93ef097-b6ea-4167-8a19-eaf49ce9fa2d" />

**Important Note:** Shown after connecting to Exchange Online or skipping for Exchange On-premise and providing email domains

#

### Report in directory
![image001](https://github.com/user-attachments/assets/8f528909-5e27-41c8-a797-0eb32fe5a513)

**Important Note:** CSV report will show as **publicDLreport_yyyy-MM-dd_HHmmss.csv** or **mailboxfwdreport_yyyy-MM-dd_HHmmss.csv** in current directory of terminal if ```-OutputPath``` not specified.

#

### CSV Report for Public Distribution Lists in Microsoft Excel
![Screenshot_CSVinExcel](https://github.com/user-attachments/assets/c7efcddb-e678-4705-9100-347ab97c4b71)


**Important Note:** PrimarySMTPAddress will show empty for internal members still apart of group with no mailbox. This will show an error in terminal and will be excluded from CSV report.

#

### CSV Report for Mailbox Forwarding in Microsoft Excel
![Screenshot_CSVinExcel](https://github.com/user-attachments/assets/7465e627-548d-42f3-8f0e-88a3211a795e)

<br></br>
## NOTES

### Supported Versions

-- Exchange Online PowerShell V2 module, version 2.0.4 or later

-- Powershell 7 or later

-- Exchange Server 2013, 2016, and 2019

#

### Exchange Online Prerequisites to Run: 

Install Exchange Online Powershell module
```powershell
Install-Module ExchangeOnlineManagement -Force
```
**Please Note:** This will require restart of terminal after install. Only use for first time accessing Exchange Online via Powershell on local machine.

#

### Disclaimers

-- The  ```-onpremEX``` switch is required when running function in Exchange Management Shell

-- For Exchange Online, you must include your Microsoft 365 tenant's onmicrosoft domain(s) to be considered internal in report

-- For Exchange Online, report results may vary due to dependency on Microsoft online services and data

-- Always test the script in a non-production environment first.

-- Review the script's code and understand its functionality before execution.

-- The script may require specific permissions or elevated privileges to run correctly.

-- The script's behavior may vary depending on the system configuration and environment.

<br></br>
## Contributing

Open to all collaboration 🙏🏽

Please follow best practice outlined below:

1. Fork from the ```main``` branch only
2. Once forked, make branch from ```main``` with relevant topic
3. Make commits to improve project on branch with detailed notes
4. Test, test, test and verify
5. Push branch to ```main``` in your Github project
6. Test, test, test and verify
7. Open pull request to ```main``` with details of changes (screenshots if applicable)

Once steps complete, I will engage to discuss changes if required and evaluate readiness for merge. Cases where pull requests are closed, I will provide detailed notes on the why and provide direction for your next pull request.

</br>

<p align="center" 
 
 **How to support?** Buy me coffee ☕️ via [Paypal](https://www.paypal.com/donate/?business=E7G9HLW2WPV22&no_recurring=1&item_name=Empowering+all+to+achieve+success+through+technology.%0A&currency_code=USD)

</p>

## License

[MIT License](https://choosealicense.com/licenses/mit/)
