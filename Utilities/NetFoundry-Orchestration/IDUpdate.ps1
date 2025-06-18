param (
    [string]$ClientID = "",
    [string]$Secret = "",
    [string]$AuthURL = "https://netfoundry-production-xfjiye.auth.us-east-1.amazoncognito.com/oauth2/token",
    [string]$Operation = "Update-SpecificIdentities",
    [string]$BaseURL = "https://gateway.production.netfoundry.io/core/v2",
    [string]$AuthPolicy,
    [string]$Identity = "0x00",
    [string]$Domain = "ANY",
    [string]$IDREGEX = "^([A-Za-z]+)\.([A-Za-z]+)\s+([a-z0-9.-]+)$", # "(FNAME).(LNAME) (DOMAIN)"
    [switch]$Silent
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-ClientCredentials {
    param (
        [string]$ClientID,
        [string]$ClientSecret,
        [string]$AuthUrl
    )

    $Body = "grant_type=client_credentials&scope=https%3A%2F%2Fgateway.production.netfoundry.io%2F%2Fignore-scope"

    $Headers = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }

    $Base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ClientID}:${ClientSecret}"))
    $Headers["Authorization"] = "Basic $Base64Auth"

    try {
        Write-Log "Requesting authentication token..." "Cyan"
        $Response = Invoke-RestMethod -Uri $AuthUrl -Method Post -Headers $Headers -Body $Body
        return $Response.access_token
    } catch {
        Write-Host "Error: Failed to retrieve authentication token." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_ | Format-List *
        exit 1
    }
}

function Get-Identities {
    param (
        [string]$Token,
        [string]$BaseUrl
    )

    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-RestMethod -Uri "$BaseUrl/endpoints" -Method Get -Headers $Headers
    } catch {
        Write-Host "Error: Failed to retrieve identities." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_ | Format-List *
        exit 1
    }
}

function Get-IdentityByIdOrName {
    param (
        [string]$Token,
        [string]$BaseUrl,
        [string]$SearchTerm
    )

    $Response = Get-Identities -Token $Token -BaseUrl $BaseUrl

    if ($Response.PSObject.Properties.Name -contains "_embedded") {
        if ($Response._embedded.PSObject.Properties.Name -contains "endpointList") {
            $Identities = $Response._embedded.endpointList
        } else {
            Write-Host "Error: Expected 'endpointList' in the response, but it was not found." -ForegroundColor Red
            exit 1
        }
    } else {
        $Identities = $Response
    }

    return $Identities | Where-Object { $_.id -eq $SearchTerm -or $_.name -eq $SearchTerm }
}

function Get-AuthPolicies {
    param (
        [string]$Token,
        [string]$BaseUrl
    )

    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    try {
        return Invoke-RestMethod -Uri "$BaseUrl/auth-policies" -Method Get -Headers $Headers
    } catch {
        Write-Host "Error: Failed to retrieve authentication policies." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_ | Format-List *
        exit 1
    }
}

function Get-AuthPolicyByIdOrName {
    param (
        [string]$Token,
        [string]$BaseUrl,
        [string]$SearchTerm
    )

    $Response = Get-AuthPolicies -Token $Token -BaseUrl $BaseUrl

    if ($Response -and $Response.PSObject.Properties.Name -contains "_embedded") {
        if ($Response._embedded -and $Response._embedded.PSObject.Properties.Name -contains "authPolicyList") {
            $AuthPolicies = $Response._embedded.authPolicyList
        } else {
            Write-Host "Error: Expected 'authPolicyList' in the response, but it was not found." -ForegroundColor Red
            exit 1
        }
    } else {
        $AuthPolicies = $Response
    }

    return $AuthPolicies | Where-Object { $_.id -eq $SearchTerm -or $_.name -eq $SearchTerm }
}

function Update-Identity {
    param (
        [string]$Token,
        [string]$BaseUrl,
        [string]$IdentityID,
        [string]$ExternalID,
        [string]$AuthPolicyID
    )

    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }

    $Body = @{
        externalId = $ExternalID
        authPolicyId = $AuthPolicyID
    } | ConvertTo-Json -Depth 2

    try {
        $Response = Invoke-RestMethod -Uri "$BaseUrl/endpoints/$IdentityID" -Method Patch -Headers $Headers -Body $Body
        return $Response
    } catch {
        Write-Host "Error: Failed to update identity ID $IdentityID" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_ | Format-List *
    }
}

function Update-SpecificIdentities {
    param (
        [string]$Token,
        [string]$BaseUrl,
        [object]$IdentitiesResponse,
        [string]$AuthPolicyID,
        [string]$CompanyDomain,
        [string]$Domain
    )

    if ($IdentitiesResponse.PSObject.Properties.Name -contains "_embedded") {
        if ($IdentitiesResponse._embedded.PSObject.Properties.Name -contains "endpointList") {
            $Identities = $IdentitiesResponse._embedded.endpointList
        } else {
            Write-Host "Error: Expected 'endpointList' in the response, but it was not found." -ForegroundColor Red
            exit 1
        }
    } else {
        $Identities = $IdentitiesResponse
    }

    foreach ($Identity in $Identities) {
        if ($Identity.name -match "$IDREGEX") {
            $NameFirst = $matches[1].ToLower()
            $NameLast = $matches[2].ToLower()
            $CompanyDomain = $matches[3].ToLower()
            $NewExternalID = "$NameFirst.$NameLast@$CompanyDomain"
            if ($Domain -eq "ANY" -or $CompanyDomain -eq $Domain) {
                if ($Identity.authPolicyId -eq $AuthPolicyID -and $Identity.externalId -eq $NewExternalID) {
                    Write-Log "Skipping Identity: $($Identity.name) -> Already up to date" "Yellow"
                    continue
                }
                Write-Log "Updating Identity: $($Identity.name) -> ExternalID: $NewExternalID, AuthPolicyID: $AuthPolicyID" "Green"
                Update-Identity -Token $Token -BaseUrl $BaseUrl -IdentityID $Identity.id -ExternalID $NewExternalID -AuthPolicyID $AuthPolicyID
            } else {
                Write-Log "Skipping Identity: $($Identity.name) -> Domain did not match $Domain." "Yellow"
            }
        } else {
            Write-Log "Skipping Identity: $($Identity.name) -> Name does not match expected pattern" "Cyan"
        }
    }
}

function Show-Help {
    Write-Host "Usage: .\update-identities.ps1 -ClientID <client_id> -Secret <client_secret> -Operation <operation> [OPTIONS]" -ForegroundColor Cyan
    Write-Host "`nOptions:"
    Write-Host "  -ClientID            Required. The Client ID for authentication. Can also be set as a PowerShell variable."
    Write-Host "  -Secret              Required. The Client Secret for authentication. Can also be set as a PowerShell variable."
    Write-Host "  -AuthURL             Optional. Default: https://netfoundry-production-xfjiye.auth.us-east-1.amazoncognito.com/oauth2/token"
    Write-Host "  -Operation           Optional. Specifies the operation to execute. Supported operations:"
    Write-Host "                       * Get-Identities"
    Write-Host "                       * Get-IdentityByIdOrName"
    Write-Host "                       * Get-AuthPolicies"
    Write-Host "                       * Get-AuthPolicyByIdOrName"
    Write-Host "                       * Update-SpecificIdentities --> Default Operations"
    Write-Host "  -BaseURL             Optional. Default: https://gateway.production.netfoundry.io/core/v2"
    Write-Host "  -AuthPolicy          Optional. Authentication policy ID or Name for filtering or updating identities."
    Write-Host "  -Identity            Optional. Identity ID or Name for lookup operations. Default: 0x00"
    Write-Host "  -Domain              Optional. Domain for filtering identities. Default: $Domain"
    Write-Host "  -Silent              Optional. Suppresses non-error messages."
    Write-Host "`nExamples:"
    Write-Host "  1. **Set Client ID and Secret as PowerShell variables** (recommended):"
    Write-Host "     `$ClientID = 'your-client-id'"
    Write-Host "     `$Secret = 'your-client-secret'"
    Write-Host "     .\update-identities.ps1 -ClientID `$ClientID -Secret `$Secret -Operation Get-Identities"
    Write-Host "`n  2. **Get all identities:**"
    Write-Host "     .\update-identities.ps1 -ClientID your-client-id -Secret your-secret -Operation Get-Identities"
    Write-Host "`n  3. **Get a specific identity by name:**"
    Write-Host "     .\update-identities.ps1 -ClientID `$ClientID -Secret `$Secret -Operation Get-IdentityByIdOrName -Identity myIdentity"
    Write-Host "`n  4. **Get authentication policies:**"
    Write-Host "     .\update-identities.ps1 -ClientID `$ClientID -Secret `$Secret -Operation Get-AuthPolicies"
    Write-Host "`n  5. **Update identities that match the pattern:**"
    Write-Host "     .\update-identities.ps1 -ClientID `$ClientID -Secret `$Secret -Operation Update-SpecificIdentities -AuthPolicy myAuthPolicyID"
    Write-Host "`n  6. **Run silently (only errors will be displayed):**"
    Write-Host "     .\update-identities.ps1 -ClientID `$ClientID -Secret `$Secret -Operation Update-SpecificIdentities -Silent"
    Write-Host "`n"
    exit 0
}

# Check if -Help is requested
if ($args -contains "-Help" -or $args -contains "--help") {
    Show-Help
}

function Print-Response {
    param (
        [object]$Response,
        [string]$Operation
    )

    if ($Response.PSObject.Properties.Name -contains "_embedded") {
        $EmbeddedKey = ($Response._embedded.PSObject.Properties.Name | Select-Object -First 1)
        $Data = $Response._embedded.$EmbeddedKey
    } else {
        $Data = $Response
    }

    if ($Data -is [System.Collections.IEnumerable] -and $Data.Count -gt 0) {
        if ($Operation -eq "Get-AuthPolicies" -or $Operation -eq "Get-AuthPolicyByIdOrName") {
            $FormattedData = $Data | ForEach-Object {
                [PSCustomObject]@{
                    id               = $_.id
                    name             = $_.name
                    primarySigners   = if ($_.primary -and $_.primary.extJwt.allowedSigners) { ($_.primary.extJwt.allowedSigners -join ", ") } else { "None" }
                    secondarySigners = if ($_.secondary -and $_.secondary.extJwt.allowedSigners) { ($_.secondary.extJwt.allowedSigners -join ", ") } else { "None" }
                }
            }
            $FormattedData | Format-Table -AutoSize
        } else {
            $Data | Select-Object name, externalId, authPolicyId, id | Format-Table -AutoSize
        }
    } elseif ($Data -is [PSCustomObject]) {
        if ($Operation -eq "Get-AuthPolicies" -or $Operation -eq "Get-AuthPolicyByIdOrName") {
            $FormattedData = [PSCustomObject]@{
                id               = $Data.id
                name             = $Data.name
                primarySigners   = if ($Data.primary -and $Data.primary.extJwt.allowedSigners) { ($Data.primary.extJwt.allowedSigners -join ", ") } else { "None" }
                secondarySigners = if ($Data.secondary -and $Data.secondary.extJwt.allowedSigners) { ($Data.secondary.extJwt.allowedSigners -join ", ") } else { "None" }
            }
            $FormattedData | Format-List
        } else {
            $Data | Select-Object name, externalId, authPolicyId, id | Format-List
        }
    } else {
        Write-Host "No relevant data found in response."
    }
}

$Token = Get-ClientCredentials -ClientID $ClientID -ClientSecret $Secret -AuthUrl $AuthURL

switch ($Operation) {
    "Get-Identities" {
        $Result = Get-Identities -Token $Token -BaseUrl $BaseURL
    }
    "Get-IdentityByIdOrName" {
        $Result = Get-IdentityByIdOrName -Token $Token -BaseUrl $BaseURL -SearchTerm $Identity
    }
    "Get-AuthPolicies" {
        $Result = Get-AuthPolicies -Token $Token -BaseUrl $BaseURL
    }
    "Get-AuthPolicyByIdOrName" {
        $Result = Get-AuthPolicyByIdOrName -Token $Token -BaseUrl $BaseURL -SearchTerm $AuthPolicy
    }
    "Update-SpecificIdentities" {
        $Policies = if (-not $AuthPolicy) { Get-AuthPolicies -Token $Token -BaseUrl $BaseURL } else { Get-AuthPolicyByIdOrName -Token $Token -BaseUrl $BaseURL -SearchTerm $AuthPolicy }
        if (-not $Policies -or $Policies.Count -eq 0) {
            Write-Host "Error: No authentication policies found." -ForegroundColor Red
            exit 1
        }
        $AuthPolicy = $Policies[0].id
        $Identities = Get-Identities -Token $Token -BaseUrl $BaseURL
        Update-SpecificIdentities -Token $Token -BaseUrl $BaseURL -IdentitiesResponse $Identities -AuthPolicyID $AuthPolicy -Domain $Domain
    }
    default {
        Write-Host "Error: Unknown operation '$Operation'" -ForegroundColor Red
        exit 1
    }
}

if ($Result -and (-not $Silent -or $Operation -ne "Update-SpecificIdentities")) {
    Print-Response -Response $Result -Operation $Operation
}

